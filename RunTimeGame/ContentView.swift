import SwiftUI

struct ContentView: View {
    @State private var gameController = GameController()
    
    var body: some View {
        Group {
            switch gameController.state {
            case .connection:
                ConnectionView(controller: gameController)
            case .lobby:
                LobbyView(controller: gameController)
            case .playing:
                PlayingView(controller: gameController)
            case .gameOver:
                GameOverView(controller: gameController)
            }
        }
        .animation(.default, value: gameController.state)
    }
}

struct ConnectionView: View {
    let controller: GameController
    
    var body: some View {
        VStack(spacing: 30) {
            Text("NearbyInteraction Game")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Button(action: {
                controller.startSearching()
            }) {
                Text("Procurar Jogador")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct LobbyView: View {
    let controller: GameController
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Conectado!")
                .font(.title)
                .bold()
            
            Text("Aguardando confirmação...")
                .foregroundColor(.secondary)
            
            Button(action: {
                controller.setReady()
            }) {
                Text(controller.isLocalReady ? "Pronto!" : "Começar Jogo")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(controller.isLocalReady ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(controller.isLocalReady)
            .padding(.horizontal, 40)
            
            Button(action: {
                controller.disconnect()
            }) {
                Text("Sair / Desconectar")
                    .foregroundColor(.red)
            }
        }
    }
}

struct PlayingView: View {
    let controller: GameController
    
    var body: some View {
        VStack {
            HStack {
                Text("Fase \(controller.phase)")
                    .font(.headline)
                Spacer()
                Button(action: {
                    controller.disconnect()
                }) {
                    Text("Sair / Desconectar")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
            .padding()
            
            Spacer()
            
            Text(String(format: "%.1f", max(controller.timeLeft, 0)))
                .font(.system(size: 80, weight: .bold, design: .monospaced))
                .foregroundColor(controller.timeLeft <= 2.0 ? .red : .primary)
            
            Text("segundos")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 15) {
                Text("Alvo")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1fm - %.1fm", controller.targetMin, controller.targetMax))
                    .font(.largeTitle)
                    .bold()
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                Text("Distância Atual")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.2fm", controller.currentDistance))
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(isWithinTarget ? .green : .orange)
            }
            
            Spacer()
        }
        .overlay {
            if controller.showFeedback {
                Text("BOA!")
                    .font(.system(size: 100, weight: .heavy))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: controller.showFeedback)
    }
    
    private var isWithinTarget: Bool {
        controller.currentDistance >= controller.targetMin && controller.currentDistance <= controller.targetMax
    }
}

struct GameOverView: View {
    let controller: GameController
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Game Over")
                .font(.system(size: 50, weight: .heavy))
                .foregroundColor(.red)
            
            Text("Vocês chegaram até a Fase \(controller.phase)")
                .font(.title3)
            
            Button(action: {
                controller.disconnect()
            }) {
                Text("Voltar ao Início")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}
