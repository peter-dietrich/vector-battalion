import SwiftUI

@main
struct VectorBattalionApp: App {
    @StateObject private var game = BattalionGame()

    var body: some Scene {
        WindowGroup("Vector Battalion") {
            ContentView(game: game)
                .frame(minWidth: 950, minHeight: 650)
        }
        .commands {
            CommandMenu("Game") {
                Button(game.isPaused ? "Resume" : "Pause") { game.togglePause() }
                    .keyboardShortcut("p", modifiers: [])
                Button("New Run") { game.reset() }
                    .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var game: BattalionGame
    var body: some View {
        ZStack {
            BattalionSceneView(game: game).ignoresSafeArea()
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        if case .active(let position) = phase {
                            game.steer(normalized: Float(min(1, max(0, position.x / max(geometry.size.width, 1)))))
                        }
                    }
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        game.steer(normalized: Float(min(1, max(0, value.location.x / max(geometry.size.width, 1)))))
                    })
            }
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("VECTOR BATTALION").font(.system(size: 24, weight: .black, design: .rounded))
                        Text("FUN CITY  •  MODERN  •  v0.1.0").font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(.cyan)
                    }
                    Spacer()
                    stat("SQUAD", "\(game.squad)")
                    stat("SCORE", "\(game.score)")
                    stat("WAVE", "\(game.wave)")
                    stat("BEST", "\(game.bestScore)")
                    Button(game.isPaused ? "RESUME" : "PAUSE") { game.togglePause() }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan.opacity(0.7))
                }
                .padding(20).background(.black.opacity(0.50))
                Spacer()
                if game.isGameOver {
                    VStack(spacing: 12) {
                        Text("BATTALION LOST").font(.system(size: 37, weight: .black, design: .rounded))
                        Text("FINAL SCORE  \(game.score)")
                        Button("DEPLOY AGAIN") { game.reset() }.buttonStyle(.borderedProminent)
                    }
                    .padding(32).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                } else if game.isPaused {
                    Text("PAUSED").font(.system(size: 44, weight: .black, design: .rounded))
                        .padding(30).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                Spacer()
                HStack {
                    Text("MOVE MOUSE / DRAG TO STEER  •  AUTO-FIRE  •  P TO PAUSE")
                    Spacer()
                    Text("SHOOT BLUE RECRUIT PODS  •  AVOID RED BLOCKERS")
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .padding(14).background(.black.opacity(0.48))
            }
            .foregroundStyle(.white)
        }
        .preferredColorScheme(.dark)
    }
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(label).font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(.white.opacity(0.65))
            Text(value).font(.system(size: 22, weight: .bold, design: .monospaced))
        }
    }
}
