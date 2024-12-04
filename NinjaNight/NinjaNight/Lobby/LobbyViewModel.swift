import Foundation
import RxSwift

class LobbyViewModel: ComposeObservableObject<LobbyViewModel.Event> {
    enum Event {
        case signOutSuccess
    }

    @Inject var authService: AuthServiceProtocol
    @Inject var cardCreateService: CardCreateServiceProtocol
    private let disposeBag = DisposeBag()
    
    @Published var isShowingJoinSheet = false
    
    func signOut() {
        authService.signOut()
            .subscribe(
                onCompleted: { [unowned self] in
                    publish(.event(.signOutSuccess))
                },
                onError: { [unowned self] error in
                    handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func codeAddingRoom () {
        isShowingJoinSheet = true
    }
    
    func handleError(_ error: Error) {
        let appError: AppError

        if let authServiceError = error as? AuthServiceError {
            switch authServiceError {
            case .invalidCredential:
                let message = "Invalid credentials. Please try again."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .userNotFound:
                let message = "User not found. Please check your account."
                appError = AppError(message: message, underlyingError: error, navigateTo: .login)
            case .networkError:
                let message = "Network error. Please check your internet connection."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .signOutFailed:
                let message = "Failed to sign out. Please try again."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .unknownError:
                let message = "An unknown error occurred. Please try again later."
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            case .firebaseError(let firebaseError):
                let message = "Firebase error: \(firebaseError.localizedDescription)"
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            default:
                let message = "An error occurred: \(error.localizedDescription)"
                appError = AppError(message: message, underlyingError: error, navigateTo: nil)
            }
        } else {
            let message = "An unexpected error occurred: \(error.localizedDescription)"
            appError = AppError(message: message, underlyingError: error, navigateTo: nil)
        }

        publish(.error(appError))
    }
    
    func createCardsForDeck() {
        let cardDefinitions: [(CardType, String)] = [
            (.spy, "查看一名玩家流派牌"),
            (.hermit, "查看一名玩家流派牌和一張手牌"),
            (.blindAssassin, "擊殺一名玩家"),
            (.jonin, "查看一名玩家流派牌後，選擇是否擊殺該玩家")
        ]

        for (cardType, cardDetail) in cardDefinitions {
            for level in 1...6 {
                let card = Card(
                    cardName: cardType.rawValue,
                    cardLevel: level,
                    cardType: cardType,
                    cardDetail: cardDetail
                )
                
                let cardID = "\(cardType)_\(level)"
                
                cardCreateService.createCard(cardID: cardID, card: card)
                    .subscribe(
                        onCompleted: {
                            print("Successfully created card: \(card.cardName) Lv.\(card.cardLevel)")
                        },
                        onError: { error in
                            print("Failed to create card: \(error.localizedDescription)")
                        }
                    )
                    .disposed(by: disposeBag)
            }
        }

        for level in 1...6 {
            let (name, detail) = getLiarDetails(forLevel: level)
            let card = Card(
                cardName: name,
                cardLevel: level,
                cardType: .liar,
                cardDetail: detail
            )
            
            let cardID = "liar_\(level)"
            
            cardCreateService.createCard(cardID: cardID, card: card)
                .subscribe(
                    onCompleted: {
                        print("Successfully created card: \(card.cardName) Lv.\(card.cardLevel)")
                    },
                    onError: { error in
                        print("Failed to create card: \(error.localizedDescription)")
                    }
                )
                .disposed(by: disposeBag)
        }

        let counterattackCards: [(String, String, String)] = [
            ("counterattack_martyr", "殉道者", "當你被盲眼刺客或上忍擊殺時，可以獲得一個榮譽標記。"),
            ("counterattack_monk", "屍還僧", "當你被盲眼刺客或上忍攻擊時，可以揭示此牌反殺對方。")
        ]
        
        for (cardID, name, detail) in counterattackCards {
            let card = Card(
                cardName: name,
                cardLevel: 0,
                cardType: .counterattack,
                cardDetail: detail
            )
            
            cardCreateService.createCard(cardID: cardID, card: card)
                .subscribe(
                    onCompleted: {
                        print("Successfully created card: \(card.cardName)")
                    },
                    onError: { error in
                        print("Failed to create card: \(error.localizedDescription)")
                    }
                )
                .disposed(by: disposeBag)
            
            // 創建特殊類型卡牌
              let specialCardID = "special_summit"
              let specialCard = Card(
                  cardName: "首腦",
                  cardLevel: 0,
                  cardType: .special,
                  cardDetail: "揭示階段若你還存活，可以揭示此牌讓你的流派直接獲勝。"
              )
              
              cardCreateService.createCard(cardID: specialCardID, card: specialCard)
                  .subscribe(
                      onCompleted: {
                          print("Successfully created card: \(specialCard.cardName)")
                      },
                      onError: { error in
                          print("Failed to create card: \(error.localizedDescription)")
                      }
                  )
                  .disposed(by: disposeBag)
        }
    }
    
    func getLiarDetails(forLevel level: Int) -> (name: String, detail: String) {
        switch level {
        case 1:
            return ("百變者", "你可以選擇場上兩位玩家包括你自己，查看流派牌後選擇是否交換，之後對方不能再確認身份。")
        case 2:
            return ("掘墓人", "查看本回合棄牌堆中的兩張牌，拿走其中一張，你可以選擇立刻發動或是之後再用。")
        case 3:
            return ("搗蛋鬼", "查看一位其他玩家流派牌，並選擇是否揭示。")
        case 4:
            return ("靈魂商販", "查看一位其他玩家的榮譽標記或流派牌，擇一查看後你可以與該玩家交換榮譽標記。")
        case 5:
            return ("竊賊", "揭示你的流派牌，然後你可以選擇一個榮譽標記數量比你多的玩家，隨機偷走他一個榮譽標記。")
        case 6:
            return ("裁判", "揭示你的流派牌，並擊殺一名玩家。")
        default:
            fatalError("Invalid level for Liar")
        }
    }
}
