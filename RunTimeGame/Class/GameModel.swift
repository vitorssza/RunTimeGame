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
    