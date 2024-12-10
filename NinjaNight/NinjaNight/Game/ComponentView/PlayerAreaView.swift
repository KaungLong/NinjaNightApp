import SwiftUI

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
