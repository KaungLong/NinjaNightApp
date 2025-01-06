import SwiftUI

struct CountdownProgressView: View {
    @Binding var actionHint: String
    let totalSeconds: Double
    @Binding var remainingSeconds: Double
    
    var body: some View {
        VStack() {
            Text(actionHint)
                .bold()
            
            ProgressView(value: remainingSeconds, total: totalSeconds)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 10)
                .padding(.horizontal, 50)

        }
    }
}

struct CountdownProgressView_Previews: PreviewProvider {
    @State static var previewRemainingSeconds = 5.0
    @State static var actionHint = "記住你得陣營"
    
    static var previews: some View {
        CountdownProgressView(
            actionHint: $actionHint,
            totalSeconds: 10,
            remainingSeconds: $previewRemainingSeconds
        )
    }
}


