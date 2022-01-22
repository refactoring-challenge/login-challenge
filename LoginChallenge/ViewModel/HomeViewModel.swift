import SwiftUI
import APIServices
import Logging
import Entities

@MainActor
private let logger: Logger = .init(label: String(reflecting: HomeView.self))

final class HomeViewModel: ObservableObject {
    @Published private(set) var user: User?

    @Published private(set) var isReloading: Bool = false
    @Published private(set) var isLoggingOut: Bool = false

    @Published var presentsActivityIndicator: Bool = false
    @Published var alertType: AlertType = .none

    enum AlertType {
        case none
        case authenticationError
        case networkError
        case serverError
        case systemError

        static func errorToAlert(_ error: Error) -> AlertType {
            switch error {
            case is AuthenticationError:
                return .authenticationError
            case is NetworkError:
                return .networkError
            case is ServerError:
                return .serverError
            default:
                return .systemError
            }
        }

        func toAlert(action: (() -> Void)?) -> Alert {
            switch self {
            case .authenticationError:
                return Alert(
                    title: Text("認証エラー"),
                    message: Text("再度ログインして下さい。"),
                    dismissButton: .default(Text("OK"), action: action)
                )
            case .networkError:
                return Alert(
                    title: Text("ネットワークエラー"),
                    message: Text("通信に失敗しました。ネットワークの状態を確認して下さい。"),
                    dismissButton: .default(Text("閉じる"), action: nil)
                )
            case .serverError:
                return Alert(
                    title: Text("サーバーエラー"),
                    message: Text("しばらくしてからもう一度お試し下さい。"),
                    dismissButton: .default(Text("閉じる"), action: nil)
                )
            default:
                return Alert(
                    title: Text("システムエラー"),
                    message: Text("エラーが発生しました。"),
                    dismissButton: .default(Text("閉じる"), action: nil)
                )
            }
        }
    }

    func loadUser() async {
        // 処理が二重に実行されるのを防ぐ。
        if isReloading { return }

        // 処理中はリロードボタン押下を受け付けない。
        isReloading = true

        do {
            // API を叩いて User を取得。
            let user = try await UserService.currentUser()

            // 取得した情報を View に反映。
            self.user = user
        } catch {
            logger.info("\(error)")
            self.alertType = AlertType.errorToAlert(error)
        }

        // 処理が完了したのでリロードボタン押下を再度受け付けるように。
        isReloading = false
    }

    func logout() async {
        Task {
            // 処理が二重に実行されるのを防ぐ。
            if isLoggingOut { return }

            // 処理中はログアウトボタン押下を受け付けない。
            isLoggingOut = false

            // Activity Indicator を表示。
            presentsActivityIndicator = true

            // API を叩いて処理を実行。
            await AuthService.logOut()

            // Activity Indicator を非表示に。
            presentsActivityIndicator = false
            // この View から遷移するのでボタンの押下受け付けは再開しない。
            // 遷移アニメーション中に処理が実行されることを防ぐ。
        }
    }
}
