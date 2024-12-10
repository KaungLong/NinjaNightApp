import SwiftUI

struct GamePhaseView: View {
    @Binding var phase: GameStage

    var body: some View {
        Text("Game Phase: \(phase.rawValue)")
            .font(.headline)
            .foregroundColor(.primary)
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
