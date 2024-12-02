import SwiftUI

struct LimitSpacer: View {
    var size: CGFloat
    var axis: Axis

    var body: some View {
        Spacer()
            .frame(
                width: axis == .horizontal ? size : nil,
                height: axis == .vertical ? size : nil
            )
    }
}

enum Axis {
    case horizontal
    case vertical
}
