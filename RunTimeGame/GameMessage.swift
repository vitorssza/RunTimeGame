import Foundation

enum GameMessage: Codable {
    case token(Data)
    case ready
    case startPhase(min: Float, max: Float)
}   
