import SwiftUI

enum GameMainActionState {
    case showFaction
}

struct GameMainActionView: View {
    @Binding var gameMainActionState: GameMainActionState
    @Binding var mainActionData: String

    var body: some View {
        switch gameMainActionState {
        case .showFaction:
            ShowFactionView(mainActionData: $mainActionData)
        }
    }
}
