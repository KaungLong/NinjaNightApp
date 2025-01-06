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
                gameMainActionState: $viewModel.gameMainActionState,
                currentPhase: $viewModel.currentPhase,
                mainActionData: $viewModel.playerFaction,
                selectedCardID: $viewModel.selectedCardID,
                seletedCards: $viewModel.seletedCards,
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
                handCards: $viewModel.handCards,
                honorTokens: [2, 3, 3, 4],
                actionHint: $viewModel.actionHint,
                totalSeconds: viewModel.totalSeconds,
                remainingSeconds: $viewModel.remainingSeconds
            )
            .navigationBarHidden(true)
            .onConsume(handleError, viewModel) { event in
                switch event {
                case .chooseCardStep1:
                    viewModel.gameMainActionState = .chooseCardStep1
                    print("切換成ChooseCardView1")
                case .chooseCardStep2:
                    print("切換成ChooseCardView2")
                }
            }
            .onAppear {
                viewModel.roundStart()
            }
        }
    }

}

struct GameContentView: View {
    @Binding var gameMainActionState: GameMainActionState
    @Binding var currentPhase: GameStage
    @Binding var mainActionData: String
    @Binding var selectedCardID: String?
    @Binding var seletedCards: [Card]

    var upcomingActions: [String]
    var player: Player
    var roundState: RoundState
    @Binding var handCards: [CardUI]
    var honorTokens: [Int]

    @Binding var actionHint: String
    let totalSeconds: Double
    @Binding var remainingSeconds: Double

    var body: some View {
        VStack(spacing: 0) {
            GamePhaseView(phase: $currentPhase)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(Color.blue.opacity(0.2))

            GameMainActionView(
                gameMainActionState: $gameMainActionState,
                mainActionData: $mainActionData,
                selectedCardID: $selectedCardID,
                cards: $seletedCards,
                actionHint: $actionHint,
                totalSeconds: totalSeconds,
                remainingSeconds: $remainingSeconds
            )
            .frame(maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))

            UpcomingActionsView(upcomingActions: upcomingActions)
                .frame(height: 80)

            PlayerAreaView(
                player: player, roundState: roundState, cardUIs: $handCards,
                honorTokens: honorTokens
            )
            .frame(height: 200)
        }
    }
}

struct GameContentView_Preview: PreviewProvider {
    static var previews: some View {
        BaseView {
            GameContentView(
                gameMainActionState: .constant(.showFaction),
                currentPhase: .constant(.draft),
                mainActionData: .constant("仙鶴1"),
                selectedCardID: .constant(""),
                seletedCards: .constant([]),
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
                handCards: .constant([
                    CardUI(
                        card: Card(
                            cardName: "隱士", cardLevel: 1, cardType: .hermit,
                            cardDetail: "測試用不多說明")),
                    CardUI(
                        card: Card(
                            cardName: "盲眼刺客", cardLevel: 4,
                            cardType: .blindAssassin, cardDetail: "測試用不多說明")),
                ]),
                honorTokens: [2, 3, 3, 4],
                actionHint: .constant(""),
                totalSeconds: 0.0,
                remainingSeconds: .constant(0.0)
            )
        }
    }
}
