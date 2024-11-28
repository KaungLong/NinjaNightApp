import Combine
import SwiftUI

struct RoomListView: View {
    @StateObject private var viewModel: RoomList = .init()
    @EnvironmentObject var navigationPathManager: NavigationPathManager

    var body: some View {
        BaseView(title: "房間列表") {
            RoomListContentView(
                rooms: $viewModel.rooms,
                gotoSelectedRoom: { invitationCode in
                    navigationPathManager.navigate(
                        to: .prepareRoom(roomInvitationCode: invitationCode)
                    )
                },
                refreshAction: viewModel.fetchRooms
            )
            .onAppear {
                viewModel.fetchRooms()
            }
        }
    }
}

struct RoomListContentView: View {
    @Binding var rooms: [Room]
    let gotoSelectedRoom: (String) -> Void
    let refreshAction: () -> Void
    var body: some View {
        NavigationView {
            List(rooms, id: \.id) { room in
                RoomRowView(room: room) {
                    if !(room.isFull ?? false) {
                        gotoSelectedRoom(room.roomInvitationCode)
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
                Text(room.rommHostID)
                    .font(.headline)
                Text(
                    "Players: \(room.currentPlayerCount ?? 0)/\(room.roomCapacity)"
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
