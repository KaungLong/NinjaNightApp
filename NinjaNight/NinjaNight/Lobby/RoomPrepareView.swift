import SwiftUI

struct RoomPrepareView: View {
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @StateObject var viewModel: RoomPrepare

    init(roomInvitationCode: String) {
        _viewModel = StateObject(
            wrappedValue: RoomPrepare(roomInvitationCode: roomInvitationCode))
    }

    var body: some View {
        BaseView {
            RoomPrepareContentView(
                roomInfo: viewModel.roomInfo,
                players: viewModel.players,
                isPlayerReady: $viewModel.isPlayerReady,
                isHost: $viewModel.isHost,
                canStartGame: $viewModel.canStartGame,
                leaveRoom: viewModel.leaveRoom,
                startGame: viewModel.startGame,
                toggleReadyStatus: viewModel.toggleReadyStatus
            )
            .navigationBarHidden(true)
            .onReceive(
                viewModel.$event,
                perform: { event in
                    guard let event = event else { return }
                    switch event {
                    case .leaveRoom:
                        navigationPathManager.path = NavigationPath()
                    case .gameStart:
                        print("gameStart")
                    }
                }
            )
            .onAppear {
                viewModel.joinRoomFlow()
            }
            .onDisappear {
                viewModel.stopListeningToPlayerList()
                viewModel.stopHeartbeat()
            }
        }
    }
}

struct RoomPrepareContentView: View {
    var roomInfo: RoomPrepare.RoomInfo
    var players: [Player]
    @Binding var isPlayerReady: Bool
    @Binding var isHost: Bool
    @Binding var canStartGame: Bool
    var leaveRoom: () -> Void
    var startGame: () -> Void
    var toggleReadyStatus: () -> Void

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
                    Circle()
                        .fill(colorForPlayer(player: player))
                        .frame(width: 10, height: 10)
                    Text(player.name)
                    Spacer()
                    Text(player.isReady ? "Ready" : "Not Ready")
                        .foregroundColor(player.isReady ? .green : .red)
                }
            }

            Spacer()

            if isHost {
                Button("Start Game", action: startGame)
                    .padding()
                    .background(canStartGame ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(!canStartGame)
            } else {
                Toggle(isOn: $isPlayerReady) {
                    Text("I'm Ready")
                        .font(.headline)
                }
                .onChange(of: isPlayerReady) { newValue in
                    toggleReadyStatus()
                }
                .padding()
            }

            Button(action: {
                leaveRoom()
            }) {
                Text("Leave Room")
                    .foregroundColor(.red)
            }
            .padding(.top)
        }
    }

    func colorForPlayer(player: Player) -> Color {
        let currentTime = Date()
        let lastHeartbeatDate = player.lastHeartbeat.dateValue()
        let timeDifference = currentTime.timeIntervalSince(lastHeartbeatDate)

        switch timeDifference {
        case 0..<10:
            return .green
        case 10..<20:
            return .yellow
        case 20..<30:
            return .red
        default:
            return .gray
        }
    }
}

struct RoomPrepareContentView_Previews: PreviewProvider {
    static var previews: some View {
        RoomPrepareContentView(
            roomInfo: RoomPrepare.RoomInfo(),
            players: [],
            isPlayerReady: .constant(false),
            isHost: .constant(true),
            canStartGame: .constant(true),
            leaveRoom: {},
            startGame: {},
            toggleReadyStatus: {}
        )
    }
}