import SwiftUI

struct CreatedRoomView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @StateObject var viewModel = CreatedRoom()

    var body: some View {
        BaseView {
            CreatedRoomContentView(
                state: $viewModel.setting,
                createdRoom: viewModel.createdRoom
            )
            .onReceive(viewModel.$event) { event in
                guard let event = event else { return }
                switch event {
                case .createdRoomsuccuss:
                    print("導頁到等待房間畫面")
                    navigationPathManager.path.append(Pages.prepareRoom(roomInvitationCode: viewModel.roomInvitationCode))
                case .createdRoomFailure(_):
                    print("房間創建失敗")
                    //補上房間建立失敗錯誤
                }
            }
        }
    }
}

struct CreatedRoomContentView: View {
    @Binding var state: CreatedRoom.Setting
    var createdRoom: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Room Setting!")
                .font(.largeTitle)
                .padding()

            roomCapacityView
            roomPublicView
            roomPasswordView
            LimitSpacer(size: 30, axis: .vertical)

            HStack {
                Spacer()
                Button("創建房間", action: createdRoom)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }

    @ViewBuilder
    private var roomCapacityView: some View {
        HStack(spacing: 0) {
            Text("房間人數")
            LimitSpacer(size: 30, axis: .horizontal)

            capacityButton(
                action: decreaseRoomCapacity,
                isDisabled: state.roomCapacity <= 5, systemImage: "minus.circle"
            )
            Text("\(state.roomCapacity)")
                .font(.title)
                .padding(.horizontal)
                .frame(width: 80)
            capacityButton(
                action: increaseRoomCapacity,
                isDisabled: state.roomCapacity >= 10, systemImage: "plus.circle"
            )
        }
        .padding()
    }

    @ViewBuilder
    private func capacityButton(
        action: @escaping () -> Void, isDisabled: Bool, systemImage: String
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(isDisabled ? .gray : .blue)
        }
        .disabled(isDisabled)
    }

    @ViewBuilder
    private var roomPublicView: some View {
        HStack(spacing: 0) {
            Text("是否公開房間")
            LimitSpacer(size: 30, axis: .horizontal)
            Toggle("", isOn: $state.isRoomPublic)
                .frame(width: 60)
        }
        .padding()
    }

    //TODO: 未來補上有設定房間公開才有密碼設置＆提示密碼為空時預設無密碼
    @ViewBuilder
    private var roomPasswordView: some View {
        HStack(spacing: 0) {
            Text("房間密碼")
            LimitSpacer(size: 30, axis: .horizontal)
            TextField("Password", text: $state.roomPassword)
                .frame(width: 120, height: 40)
                .padding([.leading], 20)
                .border(.blue, width: 2)
                .tint(.red)

        }
        .padding()
    }

    private func decreaseRoomCapacity() {
        if state.roomCapacity > 5 {
            state.roomCapacity -= 1
        }
    }

    private func increaseRoomCapacity() {
        if state.roomCapacity < 10 {
            state.roomCapacity += 1
        }
    }
}

struct CreatedRoomContentView_Previews: PreviewProvider {
    static var previews: some View {
        CreatedRoomContentView(
            state: .constant(
                CreatedRoom.Setting(
                    roomCapacity: 5,
                    isRoomPublic: true,
                    roomPassword: "")
            ),
            createdRoom: {}
        )
    }
}
