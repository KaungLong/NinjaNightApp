import SwiftUI

struct CreatedRoomView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.handleError) var handleError
    @StateObject var viewModel = CreatedRoom()

    var body: some View {
        BaseView {
            CreatedRoomContentView(
                state: $viewModel.setting,
                createdRoom: viewModel.createRoom
            )
            .onAppear {
                viewModel.initRoomName()
            }
            .onConsume(handleError, viewModel) { event in
                switch event {
                case .createdRoomSuccess:
                    navigationPathManager.navigate(
                        to: .prepareRoom(
                            roomInvitationCode: viewModel.roomInvitationCode
                        )
                    )
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

            roomNameView
            roomCapacityView
            roomPublicView
            if state.isRoomPrivate {
                roomPasswordView
            }
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
    private var roomNameView: some View {
        HStack(spacing: 0) {
            Text("房間名稱")
            LimitSpacer(size: 30, axis: .horizontal)
            TextField("Room Name", text: $state.roomName)
                .frame(height: 40)
                .padding([.leading, .trailing], 10)
                .border(Color.blue, width: 2)
        }
        .padding()
    }

    @ViewBuilder
    private var roomCapacityView: some View {
        HStack(spacing: 0) {
            Text("房間人數")
            LimitSpacer(size: 30, axis: .horizontal)

            capacityButton(
                action: decreaseRoomCapacity,
                isDisabled: state.maximumCapacity <= 5,
                systemImage: "minus.circle"
            )
            Text("\(state.maximumCapacity)")
                .font(.title)
                .padding(.horizontal)
                .frame(width: 80)
            capacityButton(
                action: increaseRoomCapacity,
                isDisabled: state.maximumCapacity >= 10,
                systemImage: "plus.circle"
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
            Toggle("", isOn: $state.isRoomPrivate)
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
        if state.maximumCapacity > 5 {
            state.maximumCapacity -= 1
        }
    }

    private func increaseRoomCapacity() {
        if state.maximumCapacity < 10 {
            state.maximumCapacity += 1
        }
    }
}

struct CreatedRoomContentView_Previews: PreviewProvider {
    static var previews: some View {
        CreatedRoomContentView(
            state: .constant(
                CreatedRoom.Setting(
                    maximumCapacity: 5,
                    isRoomPrivate: true,
                    roomPassword: "")
            ),
            createdRoom: {}
        )
    }
}
