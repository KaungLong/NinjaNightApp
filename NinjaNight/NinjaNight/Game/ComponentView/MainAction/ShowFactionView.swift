import SwiftUI

struct ShowFactionView: View {
    @Binding var mainActionData: String

    var body: some View {
        VStack {
            FactionCardView(factionName: mainActionData, imageName: "faction_image")
        }
        .navigationTitle("流派詳情")
    }
}

struct FactionCardView: View {
    let factionName: String
    let imageName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 200)
                .cornerRadius(12)
                .shadow(radius: 5)

            Text(factionName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}
