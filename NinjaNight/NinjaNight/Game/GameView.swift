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
                gameMainActionState: $viewModel.gameMainActionState, currentPhase: $viewModel.currentPhase,
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
    @Binding var gameMainActionState: GameMainActionState
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

            GameMainActionView(gameMainActionState: $gameMainActionState, mainActionData: $mainActionData)
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


struct GameContentView_Preview: PreviewProvider {
    static var previews: some View {
        BaseView {
            GameContentView(
                gameMainActionState: .constant(.showFaction), currentPhase: .constant(.draft),
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

