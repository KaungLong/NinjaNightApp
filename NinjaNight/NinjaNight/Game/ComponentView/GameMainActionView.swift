import SwiftUI

enum GameMainActionState {
    case showFaction
    case chooseCardStep1
}

struct GameMainActionView: View {
    @Binding var gameMainActionState: GameMainActionState
    @Binding var mainActionData: String
    @Binding var selectedCardID: String?
    @Binding var cards: [Card]
    
    @Binding var actionHint: String
    var totalSeconds: Double
    @Binding var remainingSeconds: Double
    
    var body: some View {
        VStack {
            switch gameMainActionState {
            case .showFaction:
                ShowFactionView(mainActionData: $mainActionData)
            case .chooseCardStep1:
                ChooseCardView(selectedCardID: $selectedCardID, cards: $cards)
            }
            
            CountdownProgressView(
                actionHint: $actionHint,
                totalSeconds: totalSeconds,
                remainingSeconds: $remainingSeconds)
        }
    }
}
