import SwiftUI

struct RoomPrepareView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @StateObject var viewModel: RoomPrepare
    
    init(roomInvitationCode: String) {
        _viewModel = StateObject(wrappedValue: RoomPrepare(roomInvitationCode: roomInvitationCode))
    }

    var body: some View {
        BaseView {
            RoomPrepareContentView(
                roomInfo: viewModel.roomInfo,
                players: viewModel.players,
                isPlayerReady: $viewModel.isPlayerReady,
                leaveRoom: {},
                startHeartbeat: {},
                stopHeartbeat: {}
            )
            .onAppear {
                viewModel.joinRoomFlow()
            }
        }
    }
}

struct RoomPrepareContentView: View {
    var roomInfo: RoomPrepare.RoomInfo
    var players: [Player]
    @Binding var isPlayerReady: Bool
    var leaveRoom: () -> Void
    var startHeartbeat: () -> Void
    var stopHeartbeat: () -> Void
    
    var body: some View {
        VStack {
            Text("Room: \(roomInfo.inviteCode)")
                .font(.title2)
                .padding()

            Text("Host: \(roomInfo.hostName)")
                .font(.subheadline)
                .padding(.bottom)

            Text("Players: \(roomInfo.currentPlayers)/\(roomInfo.maxPlayers)")
                .font(.subheadline)
                .padding(.bottom)

            List(players, id: \.id) { player in
                HStack {
                    Text(player.name)
                    Spacer()
                    Text(player.isReady ? "Ready" : "Not Ready")
                        .foregroundColor(player.isReady ? .green : .red)
                }
            }

            Spacer()

            Toggle(isOn: $isPlayerReady) {
                Text("I'm Ready")
                    .font(.headline)
            }
            .padding()

            Button(action: {
                leaveRoom()
            }) {
                Text("Leave Room")
                    .foregroundColor(.red)
            }
            .padding(.top)
        }
        .onAppear {
            startHeartbeat()
        }
        .onDisappear {
            stopHeartbeat()
        }
    }
}


struct RoomPrepareContentView_Previews: PreviewProvider {
    static var previews: some View {
        RoomPrepareContentView(
            roomInfo: RoomPrepare.RoomInfo(),
            players: [],
            isPlayerReady: .constant(false),
            leaveRoom: {},
            startHeartbeat: {},
            stopHeartbeat: {}
        )
    }
}


   

