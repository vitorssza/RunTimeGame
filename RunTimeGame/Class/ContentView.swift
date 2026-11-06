import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    
    init(viewModel: GameViewModel = GameViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }
    
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

#Preview("1. Desconectado") {
    let vm = GameViewModel()
    vm.state = .disconnected
    return ContentView(viewModel: vm)
}

#Preview("2. Conectando") {
    let vm = GameViewModel()
    vm.state = .connecting
    return ContentView(viewModel: vm)
}

#Preview("3. Pronto - Aguardando Confirmacao") {
    let vm = GameViewModel()
    vm.state = .ready
    vm.isReady = false
    return ContentView(viewModel: vm)
}

#Preview("4. Pronto - Aguardando)") {
    let vm = GameViewModel()
    vm.state = .ready
    vm.isReady = true
    return ContentView(viewModel: vm)
}

#Preview("5. Jogando - Distancia(Verde)") {
    let vm = GameViewModel()
    vm.state = .playing
    vm.showBoa = false
    vm.phase = 1
    vm.targetMin = 1.0
    vm.targetMax = 2.5
    vm.niManager.distance = 1.8
    vm.timeRemaining = 15
    return ContentView(viewModel: vm)
}

#Preview("6. Jogando - Distancia(Vermelho)") {
    let vm = GameViewModel()
    vm.state = .playing
    vm.showBoa = false
    vm.phase = 2
    vm.targetMin = 2.0
    vm.targetMax = 3.5
    vm.niManager.distance = 5.20
    vm.timeRemaining = 8
    return ContentView(viewModel: vm)
}

#Preview("7. Jogando - Calculando Distancia") {
    let vm = GameViewModel()
    vm.state = .playing
    vm.showBoa = false
    vm.phase = 1
    vm.targetMin = 1.0
    vm.targetMax = 2.0
    vm.niManager.distance = nil
    vm.timeRemaining = 20
    return ContentView(viewModel: vm)
}

#Preview("8. Jogando - Feedback") {
    let vm = GameViewModel()
    vm.state = .playing
    vm.showBoa = true
    return ContentView(viewModel: vm)
}

#Preview("9. Game Over") {
    let vm = GameViewModel()
    vm.state = .gameOver
    return ContentView(viewModel: vm)
}
