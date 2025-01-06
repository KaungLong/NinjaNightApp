import SwiftUI

struct ChooseCardView: View {
    @Binding var selectedCardID: String?
    @Binding var cards: [Card]
    @State private var tempSelectedCardID: String? = nil  

    var body: some View {
        VStack {
            HStack(spacing: 16) {
                ForEach(cards.prefix(3)) { card in
                    CardView(cardUI: .constant(CardUI(card: card)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tempSelectedCardID == card.id ? Color.red : Color.clear, lineWidth: 3)
                        )
                        .onTapGesture {
                            withAnimation {
                                tempSelectedCardID = (tempSelectedCardID == card.id) ? nil : card.id
                            }
                        }
                }
            }
            .padding()

            Button(action: confirmSelection) {
                Text("確定")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
            .disabled(tempSelectedCardID == nil)
            .opacity(tempSelectedCardID == nil ? 0.5 : 1.0)
        }
    }

    private func confirmSelection() {
        if let tempSelectedCardID = tempSelectedCardID {
            selectedCardID = tempSelectedCardID
            print("選擇的卡片ID: \(selectedCardID ?? "未選擇")")
        }
    }
}
