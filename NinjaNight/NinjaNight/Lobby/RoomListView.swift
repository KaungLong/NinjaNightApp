import Combine
import SwiftUI

struct RoomListView: View {
    @StateObject private var viewModel: RoomList = .init()
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.handleError) var handleError

    @State private var showPasswordAlert = false
    @State private var passwordInput = ""
    @State private var selectedRoom: Room?

    var body: some View {
        BaseView(title: "房間列表") {
            RoomListContentView(
                rooms: $viewModel.rooms,
                gotoSelectedRoom: viewModel.tryToJoinRoom,
                refreshAction: viewModel.fetchRooms
            )
            .onConsume(handleError, viewModel) { event in
                switch event {
                case .gotoSelectedRoom(let invitationCode):
                    navigationPathManager.navigate(
                        to: .prepareRoom(roomInvitationCode: invitationCode)
                    )
                case .needPassword(let room):
                    selectedRoom = room
                    showPasswordAlert = true
                }
            }
            .onAppear {
                viewModel.fetchRooms()
            }
            .alert(
                "Enter Room Password", isPresented: $showPasswordAlert,
                actions: {
                    SecureField("Password", text: $passwordInput)
                    Button("Join", role: .none) {
                        guard let room = selectedRoom else { return }
                        viewModel.joinRoomWithPassword(
                            room: room, password: passwordInput)
                        passwordInput = ""
                    }
                    Button("Cancel", role: .cancel) {
                        passwordInput = ""
                    }
                },
                message: {
                    Text("This room requires a password.")
                }
            )
        }
    }
}

struct RoomListContentView: View {
    @Binding var rooms: [Room]
    let gotoSelectedRoom: (Room) -> Void
    let refreshAction: () -> Void
    var body: some View {
        NavigationView {
            List(rooms, id: \.id) { room in
                RoomRowView(room: room) {
                    if !(room.isFull ?? false) {
                        gotoSelectedRoom(room)
                    }
                }
            }
            .navigationTitle("Available Rooms")
            .refreshable {
                refreshAction()
            }
        }
    }
}

struct RoomRowView: View {
    let room: Room
    let onTap: () -> Void
    @State private var isPressed: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(room.roomName)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.blue)
                Text(room.rommHostID)
                    .font(.headline)
                Text(
                    "Players: \(room.currentPlayerCount ?? 0)/\(room.maximumCapacity)"
                )
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            Spacer()
            if room.isFull ?? false {
                Text("Full")
                    .foregroundColor(.red)
                    .bold()
            } else {
                Text("Open")
                    .foregroundColor(.green)
                    .bold()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(isPressed ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(10)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
                onTap()
            }
        }
    }
}
