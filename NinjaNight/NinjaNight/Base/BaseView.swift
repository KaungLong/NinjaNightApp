import SwiftUI

struct BaseView<Content: View>: View {
    var title: String?
    var backgroundColor: Color
    var content: Content

    init(
        title: String,
        backgroundColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    init(
        backgroundColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        VStack {
            if let title = title {
                VStack {
                    Text(title)
                        .font(.largeTitle)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                    Divider()
                }
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
            }

            content
                .padding()
                .background(backgroundColor)
                .cornerRadius(10)
                .shadow(radius: 5)

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .edgesIgnoringSafeArea(.bottom)
    }
}
