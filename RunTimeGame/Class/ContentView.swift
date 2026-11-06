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
