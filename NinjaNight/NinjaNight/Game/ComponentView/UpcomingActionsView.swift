import SwiftUI

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
