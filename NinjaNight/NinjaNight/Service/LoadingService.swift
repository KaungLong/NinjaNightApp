import SwiftUI

class LoadingManager: ObservableObject {
    static let shared = LoadingManager()
    @Published var isLoading = false
}

struct LoadingOverlay: View {
    @EnvironmentObject var loadingManager: LoadingManager

    var body: some View {
        if loadingManager.isLoading {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("加载中...")
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EmptyView()
        }
    }
}
