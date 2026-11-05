### Arquivo: \⁠ ./RunTimeGame/ConnectionManager.swift\ ⁠
⁠ swift
import MultipeerConnectivity
import SwiftUI

@Observable
class ConnectionManager: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser!
    var browser: MCNearbyServiceBrowser!
    var peerID: MCPeerID!
    var connectedPeer: MCPeerID?
    
    var onDataReceived: ((Data) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    
    override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "nirungame")
        advertiser.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "nirungame")
        browser.delegate = self
    }
    
    func startSearch() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stopSearch() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    func disconnect() {
        stopSearch()
        session.disconnect()
        connectedPeer = nil
    }
    
    func send(data: Data) {
        guard let peer = connectedPeer else { return }
        try? session.send(data, toPeers: [peer], with: .reliable)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            if state == .connected {
                self.connectedPeer = peerID
                self.stopSearch()
                self.onConnected?()
            } else if state == .notConnected {
                self.connectedPeer = nil
                self.onDisconnected?()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.onDataReceived?(data)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
 ⁠

---

### Arquivo: \⁠ ./RunTimeGame/NIManager.swift\ ⁠
⁠ swift
import NearbyInteraction
import SwiftUI

@Observable
class NIManager: NSObject, NISessionDelegate {
    var session: NISession?
    var distance: Float?
    
    var onTokenGenerated: ((Data) -> Void)?
    
    func start() {
        session = NISession()
        session?.delegate = self
        
        if let token = session?.discoveryToken,
           let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
            onTokenGenerated?(data)
        }
    }
    
    func provideRemoteToken(_ data: Data) {
        if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
            let config = NINearbyPeerConfiguration(peerToken: token)
            session?.run(config)
        }
    }
    
    func stop() {
        session?.invalidate()
        session = nil
        distance = nil
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        if let object = nearbyObjects.first, let dist = object.distance {
            DispatchQueue.main.async {
                self.distance = dist
            }
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {}
    func sessionWasSuspended(_ session: NISession) {}
    func sessionSuspensionEnded(_ session: NISession) {}
    func session(_ session: NISession, didInvalidateWith error: Error) {}
}
 ⁠

---

### Arquivo: \⁠ ./RunTimeGame/GameViewModel.swift\ ⁠
⁠ swift
import SwiftUI

@Observable
class GameViewModel {
    var connectionManager = ConnectionManager()
    var niManager = NIManager()
    
    var state: GameState = .disconnected
    var phase: Int = 1
    var timeRemaining: Int = 10
    var targetMin: Float = 0.0
    var targetMax: Float = 0.0
    var showBoa: Bool = false
    var isReady: Bool = false
    var isOpponentReady: Bool = false
    
    private var timer: Timer?
    
    var isHost: Bool {
        guard let myID = connectionManager.peerID, let peerID = connectionManager.connectedPeer else { return false }
        return myID.hashValue < peerID.hashValue
    }
    
    init() {
        connectionManager.onConnected = {
            self.state = .ready
            self.niManager.start()
        }
        
        connectionManager.onDisconnected = {
            self.resetGame()
        }
        
        connectionManager.onDataReceived = { data in
            self.handleData(data)
        }
        
        niManager.onTokenGenerated = { data in
            self.sendAction(GameAction(type: .token, token: data, minDist: nil, maxDist: nil, phase: nil))
        }
    }
    
    func startSearch() {
        state = .connecting
        connectionManager.startSearch()
    }
    
    func exitGame() {
        connectionManager.disconnect()
        resetGame()
    }
    
    func markReady() {
        isReady = true
        sendAction(GameAction(type: .ready, token: nil, minDist: nil, maxDist: nil, phase: nil))
        checkStartGame()
    }
    
    func requestPlayAgain() {
        sendAction(GameAction(type: .playAgain, token: nil, minDist: nil, maxDist: nil, phase: nil))
        prepareForNewMatch()
    }
    
    private func checkStartGame() {
        if isReady && isOpponentReady {
            state = .playing
            if isHost {
                startNewPhase()
            }
        }
    }
    
    private func resetGame() {
        timer?.invalidate()
        timer = nil
        niManager.stop()
        state = .disconnected
        phase = 1
        timeRemaining = 10
        isReady = false
        isOpponentReady = false
        showBoa = false
    }
    
    private func sendAction(_ action: GameAction) {
        if let data = try? JSONEncoder().encode(action) {
            connectionManager.send(data: data)
        }
    }
    
    private func handleData(_ data: Data) {
        guard let action = try? JSONDecoder().decode(GameAction.self, from: data) else { return }
        
        switch action.type {
        case .token:
            if let tokenData = action.token {
                niManager.provideRemoteToken(tokenData)
            }
        case .ready:
            isOpponentReady = true
            checkStartGame()
        case .startPhase:
            if let min = action.minDist, let max = action.maxDist, let ph = action.phase {
                self.phase = ph
                self.targetMin = min
                self.targetMax = max
                self.timeRemaining = 10
                self.startTimer()
                self.showBoaTemp()
            }
        case .gameOver:
            self.state = .gameOver
            self.timer?.invalidate()
            
        case .playAgain:
            self.prepareForNewMatch()
        }
    }
    
    private func startNewPhase() {
        let minRange = Float.random(in: 2...5)
        let maxRange = minRange + Float.random(in: 1...2)
        
        sendAction(GameAction(type: .startPhase, token: nil, minDist: minRange, maxDist: maxRange, phase: phase))
        
        self.targetMin = minRange
        self.targetMax = maxRange
        self.timeRemaining = 10
        self.startTimer()
        self.showBoaTemp()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.tickTimer()
        }
    }
    
    private func tickTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timer?.invalidate()
            if isHost {
                evaluateResult()
            }
        }
    }
    
    private func evaluateResult() {
        guard let dist = niManager.distance else {
            endGame()
            return
        }
        
        if dist >= targetMin && dist <= targetMax {
            phase += 1
            startNewPhase()
        } else {
            endGame()
        }
    }
    
    private func endGame() {
        state = .gameOver
        sendAction(GameAction(type: .gameOver, token: nil, minDist: nil, maxDist: nil, phase: nil))
    }
    
    private func showBoaTemp() {
        if phase > 1 {
            showBoa = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showBoa = false
            }
        }
    }
    
    private func prepareForNewMatch() {
        timer?.invalidate()
        state = .ready
        phase = 1
        timeRemaining = 10
        isReady = false
        isOpponentReady = false
        showBoa = false
    }
}
 ⁠

---

### Arquivo: \⁠ ./RunTimeGame/RunTimeGameApp.swift\ ⁠
⁠ swift
import SwiftUI

@main
struct RunTimeGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
 ⁠

---

### Arquivo: \⁠ ./RunTimeGame/ContentView.swift\ ⁠
⁠ swift
import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    
    var body: some View {
        VStack {
            
            switch viewModel.state {
            case .disconnected:
                Button("Buscar") {
                    viewModel.startSearch()
                }
                .buttonStyle(.borderedProminent)
                
            case .connecting:
                ProgressView("Buscando e conectando...")
                Button("Cancelar") {
                    viewModel.exitGame()
                }
                .padding()
                .buttonStyle(.borderedProminent)
                
            case .ready:
                Text("Conectado!")
                    .font(.title)
                    .padding()
                
                if viewModel.isReady {
                    Text("Aguardando")
                } else {
                    Button("Começar Jogo") {
                        viewModel.markReady()
                    }
                    .font(.title)
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Sair") {
                    viewModel.exitGame()
                }
                .padding()
                
            case .playing:
                if viewModel.showBoa {
                    Text("BOA!")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.scale)
                } else {
                    Text("Fase \(viewModel.phase)")
                        .font(.largeTitle)
                        .bold()
                    
                    Text(String(format: "Fique dentro de: %.1fm - %.1fm", viewModel.targetMin, viewModel.targetMax))
                        .font(.title2)
                        .padding()
                    
                    if let dist = viewModel.niManager.distance {
                        Text(String(format: "Distância atual: %.2fm", dist))
                            .font(.title)
                            .foregroundColor(dist >= viewModel.targetMin && dist <= viewModel.targetMax ? .green : .red)
                    } else {
                        Text("Calculando distância")
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(viewModel.timeRemaining) segundos")
                        .font(.system(size: 80, weight: .bold))
                        .padding()
                }
                
                Spacer()
                
                Button("Sair") {
                    viewModel.exitGame()
                }
                .padding()
                
            case .gameOver:
                Text("Game Over!")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                    .bold()
                
                HStack {
                    Button("Jogar Novamente") {
                        viewModel.requestPlayAgain()
                    }
                    .font(.title2)
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    Button("Sair da sessão") {
                        viewModel.exitGame()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
            }
        }
        .padding()
        .animation(.easeInOut, value: viewModel.state)
        .animation(.easeInOut, value: viewModel.showBoa)
    }
}

#Preview {
    ContentView()
}
 ⁠

---

### Arquivo: \⁠ ./RunTimeGame/GameModel.swift\ ⁠
⁠ swift
import Foundation

enum GameState {
    case disconnected, connecting, ready, playing, gameOver
}

struct GameAction: Codable {
    let type: ActionType
    let token: Data?
    let minDist: Float?
    let maxDist: Float?
    let phase: Int?
    
    enum ActionType: String, Codable {
        case token, ready, startPhase, gameOver, playAgain
    }
}
 ⁠

---

