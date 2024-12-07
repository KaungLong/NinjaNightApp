import SwiftUI

struct GameLoadingView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.handleError) var handleError
    @StateObject var viewModel: GameLoading
    @Inject private var loadingManager: LoadingManager

    init(roomID: String) {
        _viewModel = StateObject(
            wrappedValue: GameLoading(roomID: roomID))
    }

    var body: some View {
        BaseView(title: "Gameing") {
            GameLoadingContentView(
                loadingMessage: $viewModel.loadingMessage,
                currentSettingProgress: $viewModel.currentSettingProgress
            )
            .navigationBarHidden(true)
            .onConsume(handleError, viewModel) { event in
                switch event {
                case .loadingDone(let message):
                    navigationPathManager.navigate(to: .game)
                }
            }
            .onAppear {
                viewModel.setupGame()
            }
        }
    }
}

struct GameLoadingContentView: View {
    @Binding var loadingMessage: String
    @Binding var currentSettingProgress: Double

    var body: some View {
        VStack {
            Text("Game Setup Progress")
                .font(.headline)
            Text(loadingMessage)
                .font(.subheadline)
                .padding(.top, 8)
            ProgressView(value: currentSettingProgress, total: 1.0)
                .padding(.top, 16)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
    }
}

struct GameLoadingContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameLoadingContentView(
            loadingMessage: .constant("test"),
            currentSettingProgress: .constant(0.6)

        )
    }
}
