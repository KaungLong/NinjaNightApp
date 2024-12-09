import FirebaseCore
import SwiftUI

struct GameView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.handleError) var handleError
    @StateObject var viewModel: Game

    init(roomID: String) {
        _viewModel = StateObject(
            wrappedValue: Game(roomID: roomID))
    }

    var body: some View {
        BaseView {
            GameContentView(
                currentPhase: $viewModel.currentPhase,
                mainActionData: $viewModel.playerFaction,
                upcomingActions: ["密探1", "密探4", "密探6"],
                player: Player(
                    name: "GGdog",
                    isReady: true,
                    isOnline: true,
                    lastHeartbeat: Timestamp(date: Date())
                ),
                roundState: RoundState(
                    faction: "浪人",
                    isFactionRevealed: false,
                    currentHand: [],
                    isAlive: true
                ),
                cardUIs: [
                    CardUI(
                        card: Card(
                            cardName: "隱士", cardLevel: 1, cardType: .hermit,
                            cardDetail: "測試用不多說明")),
                    CardUI(
                        card: Card(
                            cardName: "盲眼刺客", cardLevel: 4,
                            cardType: .blindAssassin, cardDetail: "測試用不多說明")),
                ],
                honorTokens: [2, 3, 3, 4]
            )
            .navigationBarHidden(true)
            .onConsume(handleError, viewModel) { event in
             
            }
            .onAppear {
                viewModel.roundStart()
            }
        }
        .padding()
    }

}

struct GameContentView: View {
    @Binding var currentPhase: GameStage
    @Binding var mainActionData: String
    var upcomingActions: [String]
    var player: Player
    var roundState: RoundState
    var cardUIs: [CardUI]
    var honorTokens: [Int]

    var body: some View {
        VStack(spacing: 0) {
            GamePhaseView(phase: $currentPhase)
                .frame(maxWidth: .infinity, maxHeight: 40)
                .padding()
                .background(Color.blue.opacity(0.2))

            GameMainActionView(mainActionData: $mainActionData)
                .frame(maxHeight: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))

            UpcomingActionsView(upcomingActions: upcomingActions)
                .frame(height: 100)
                .padding(.vertical)

            PlayerAreaView(
                player: player, roundState: roundState, cardUIs: cardUIs,
                honorTokens: honorTokens
            )
            .frame(height: 200)
            .padding(.bottom)
        }
    }
}

struct GamePhaseView: View {
    @Binding var phase: GameStage

    var body: some View {
        Text("Game Phase: \(phase.rawValue)")
            .font(.headline)
            .foregroundColor(.primary)
    }
}

struct GameMainActionView: View {
    @StateObject private var gameNavigationPathManager = NavigationPathManager()
    @Binding var mainActionData: String

    var body: some View {
        ShowFactionView(mainActionData: $mainActionData)
    }
}

struct ShowFactionView: View {
    @Binding var mainActionData: String

    var body: some View {
        VStack {
            Text("你的流派是: \(mainActionData)")
                .font(.title)
                .foregroundColor(.primary)
        }
        .navigationTitle("流派詳情")
    }
}

struct UpcomingActionsView: View {
    let upcomingActions: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(upcomingActions, id: \.self) { action in
                    Text(action)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PlayerAreaView: View {
    let player: Player
    let roundState: RoundState
    @State var cardUIs: [CardUI]
    @State var honorTokens: [Int]

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                NinjaCardView()
                Text("\(player.name)")
                    .font(.headline)
                Text("Score: \(player.score)")
                    .font(.subheadline)
                HonorTokenGrid(tokens: honorTokens)
            }
            .padding()
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
            .frame(width: UIScreen.main.bounds.width / 4)

            HStack(spacing: 16) {
                ForEach($cardUIs.indices, id: \.self) { index in
                    CardView(cardUI: $cardUIs[index])
                }
            }
        }
        .padding(.horizontal)
    }
}

struct NinjaCardView: View {
    var body: some View {
        Image(systemName: "rectangle.portrait")
            .resizable()
            .scaledToFit()
            .frame(height: 80)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .padding(.bottom, 8)
    }
}

struct HonorTokenGrid: View {
    let tokens: [Int]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(tokens.chunked(into: 3), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { token in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(token)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
    }
}

struct CardView: View {
    @Binding var cardUI: CardUI

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.portrait")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            VStack(spacing: 4) {
                Text(cardUI.card.cardName)
                    .font(.headline)
                Text("Level \(cardUI.card.cardLevel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(cardUI.card.cardDetail)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(width: 120, height: 200)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .offset(cardUI.offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    cardUI.offset = gesture.translation
                }
                .onEnded { _ in
                    withAnimation {
                        cardUI.offset = .zero
                    }
                }
        )
    }
}

struct GameContentView_Preview: PreviewProvider {
    static var previews: some View {
        BaseView {
            GameContentView(
                currentPhase: .constant(.draft),
                mainActionData: .constant("仙鶴1"),
                upcomingActions: ["密探1", "密探4", "密探6"],
                player: Player(
                    name: "GGdog",
                    isReady: true,
                    isOnline: true,
                    lastHeartbeat: Timestamp(date: Date())
                ),
                roundState: RoundState(
                    faction: "浪人",
                    isFactionRevealed: false,
                    currentHand: [],
                    isAlive: true
                ),
                cardUIs: [
                    CardUI(
                        card: Card(
                            cardName: "隱士", cardLevel: 1, cardType: .hermit,
                            cardDetail: "測試用不多說明")),
                    CardUI(
                        card: Card(
                            cardName: "盲眼刺客", cardLevel: 4,
                            cardType: .blindAssassin, cardDetail: "測試用不多說明")),
                ], honorTokens: [2, 3, 3, 4]
            )
        }
    }
}

struct CardUI {
    var card: Card
    var offset: CGSize = .zero
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

enum GameStage: String, Decodable {
    case draft = "輪抽階段"
    case spy = "密探"
    case hermit = "隱士"
    case liar = "騙徒"
    case blindAssassin = "盲眼刺客"
    case jonin = "上忍"
    case reveal = "揭示階段"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GameStage(rawValue: rawValue) ?? .draft
    }
}
