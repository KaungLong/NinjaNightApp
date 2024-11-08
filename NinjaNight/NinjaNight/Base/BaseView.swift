import SwiftUI

struct BaseView<Content: View>: View {
    var title: String
    var backgroundColor: Color
    var content: Content

    init(
        title: String, backgroundColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)

            Divider()

            content
                .padding()
                .background(backgroundColor)
                .cornerRadius(10)
                .shadow(radius: 5)

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .edgesIgnoringSafeArea(.all)
    }
}
