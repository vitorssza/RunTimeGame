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
                
                ZStack {
                    Image ("sessao")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        Text ("Jogo dos \n5 segundos")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        
                        Text ("Busque um parceiro e jogue")
                            .fontWeight(.regular)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.bottom,30)
                        
                        
                        Button("Buscar parceiro") {
                            viewModel.startSearch()
                        }
                        .buttonStyle(.glass)
                        .frame(maxWidth:.infinity)
                        .foregroundStyle(.white)
                    }
                    .padding(.bottom, 80)
                    
                }
                
            case .connecting:
                ZStack {
                    Color.azul.ignoresSafeArea()
                    VStack {
                        
                        Text ("Conectando...")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding()
                        
                        Button("Cancelar") {
                            viewModel.exitGame()
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                    }
                }
                
            case .ready:
                ZStack {
                    Image ("conectado")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer ()
                        
                        Text("Conectado!")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        
                        if viewModel.isReady {
                            Text("Aguardando")
                        } else {
                            Button("Iniciar Jogo") {
                                viewModel.markReady()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Button("Sair") {
                            viewModel.exitGame()
                        }
                        .padding()
                        .foregroundStyle(.white)
                    }
                    .padding(.bottom, 80)
                }
                
            case .playing:
                if viewModel.showBoa {
                    
                    ZStack {
                        Image ("ganhou")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        Text("Parabéns!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale)
                    }
                    
                } else {
                    
                    ZStack {
                        Image("time")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        VStack {
                            Text("Fase \(viewModel.phase)")
                                .font(.largeTitle)
                                .bold()
                                .foregroundStyle(.white)
                            
                            VStack (spacing: -12) {
                                Text("Fique dentro de")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                
                                Text(String(
                                    format: "%.1fm - %.1fm",
                                    viewModel.targetMin,
                                    viewModel.targetMax))
                                .font(.system(size: 24, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .padding()
                            }
                            .padding(.top)
                            
                            Rectangle()
                                .fill(Color.gray)
                                .frame(height: 2)
                                .cornerRadius(1)
                                .padding(.horizontal)
                                .padding(.bottom, 32)
                            
                            
                            if let dist = viewModel.niManager.distance {
                                
                                Text("Distância entre seu parceiro")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(.white)
                                
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "figure.stand")
                                        .font(.system(size: 30))
                                        .foregroundStyle(
                                            dist >= viewModel.targetMin && dist <= viewModel.targetMax ? .green : .red)
                                    Rectangle()
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                        .foregroundStyle(
                                            dist >= viewModel.targetMin && dist <= viewModel.targetMax ? .green : .red)                                        .frame(height: 1)
                                    
                                    Text(String(format: "%.2fm", dist))
                                        .font(.system(size: 40, weight: .bold))
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .layoutPriority(1)
                                        .foregroundStyle(
                                            dist >= viewModel.targetMin && dist <= viewModel.targetMax ? .green : .red)
                                    
                                    Rectangle()
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                        .foregroundStyle(
                                            dist >= viewModel.targetMin && dist <= viewModel.targetMax ? .green : .red)                                        .frame(height: 1)
                                    
                                    Image(systemName: "figure.stand")
                                        .font(.system(size: 30))
                                        .foregroundStyle(
                                            dist >= viewModel.targetMin && dist <= viewModel.targetMax ? .green : .red)                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 32)
                                
                            } else {
                                Text("Calculando distância")
                                    .foregroundColor(.white)
                            }
                            
                            Text("\(viewModel.timeRemaining)\nsegundos")
                                .font(.system(size: 40, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .padding(.top, 300)
                        }
                    }
                }
                
                Spacer()
                
                Button("Sair") {
                    viewModel.exitGame()
                }
                .padding()
                
            case .gameOver:
                ZStack {
                    Image ("perdeu")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    VStack {
                        Text("Você perdeu!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .bold()
                        
                        Button("Jogar Novamente") {
                            viewModel.requestPlayAgain()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                        
                        Button("Sair da sessão") {
                            viewModel.exitGame()
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.white)
                        .padding()
                    }
                }
            }
        }
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
