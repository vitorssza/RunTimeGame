import SwiftUI
import Combine

enum AppState {
    case connection
    case lobby
    case playing
    case gameOver
}

@Observable
class GameController {
    var state: AppState = .connection
    var phase: Int = 1
    var timeLeft: Double = 5.0
    var targetMin: Float = 0.0
    var targetMax: Float = 0.0
    var currentDistance: Float = 0.0
    
    var isLocalReady: Bool = false
    var isRemoteReady: Bool = false
    var showFeedback: Bool = false
    
    private let connectivityManager = ConnectivityManager()
    private let niManager = NIManager()
    private var timer: Timer?
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        connectivityManager.onConnected = { [weak self] in
            self?.state = .lobby
            self?.shareNIToken()
        }
        
        connectivityManager.onDisconnected = { [weak self] in
            self?.resetGame()
        }
        
        connectivityManager.onDataReceived = { [weak self] data in
            self?.handleReceivedData(data)
        }
        
        niManager.onDistanceUpdated = { [weak self] distance in
            self?.currentDistance = distance
        }
    }
    
    func startSearching() {
        connectivityManager.startSearching()
    }
    
    func disconnect() {
        connectivityManager.disconnect()
        resetGame()
    }
    
    func setReady() {
        isLocalReady = true
        send(message: .ready)
        checkLobbyReadiness()
    }
    
    private func shareNIToken() {
        guard let token = niManager.localToken,
              let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else { return }
        send(message: .token(data))
    }
    
    private func send(message: GameMessage) {
        if let data = try? JSONEncoder().encode(message) {
            connectivityManager.send(data: data)
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        guard let message = try? JSONDecoder().decode(GameMessage.self, from: data) else { return }
        
        switch message {
        case .token(let tokenData):
            if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: tokenData) {
                niManager.startSession(with: token)
            }
        case .ready:
            isRemoteReady = true
            checkLobbyReadiness()
        case .startPhase(let min, let max):
            targetMin = min
            targetMax = max
            startCountdown()
        }
    }
    
    private func checkLobbyReadiness() {
        if isLocalReady && isRemoteReady {
            state = .playing
            if connectivityManager.isHost {
                generateAndSendNextPhase()
            }
        }
    }
    
    private func generateAndSendNextPhase() {
        let newMin = Float.random(in: 1.0...10.0)
        let newMax = newMin + 2.0
        
        targetMin = newMin
        targetMax = newMax
        
        send(message: .startPhase(min: newMin, max: newMax))
        startCountdown()
    }
    
    private func startCountdown() {
        timeLeft = 5.0
        showFeedback = false
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeLeft -= 0.1
            
            if self.timeLeft <= 0 {
                self.timer?.invalidate()
                self.evaluatePhase()
            }
        }
    }
    
    private func evaluatePhase() {
        let isSuccess = currentDistance >= targetMin && currentDistance <= targetMax
        
        if isSuccess {
            showFeedback = true
            phase += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }
                if self.connectivityManager.isHost {
                    self.generateAndSendNextPhase()
                }
            }
        } else {
            state = .gameOver
        }
    }
    
    private func resetGame() {
        timer?.invalidate()
        niManager.stopSession()
        state = .connection
        phase = 1
        isLocalReady = false
        isRemoteReady = false
        currentDistance = 0.0
        showFeedback = false
    }
}
