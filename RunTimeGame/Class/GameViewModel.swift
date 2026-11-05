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
