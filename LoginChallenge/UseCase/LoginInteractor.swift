import Foundation
import Logging
import APIServices

protocol LoginInteractor {
    func logInWith(id: String, password: String) async throws
}

final class LoginInteractorImpl: LoginInteractor {

    // String(reflecting:) はモジュール名付きの型名を取得するため。
    private let logger: Logger = .init(label: String(reflecting: LoginViewController.self))

    func logInWith(id: String, password: String) async throws {
        Task {
            do {
                // API を叩いて処理を実行。
                try await AuthService.logInWith(id: id, password: password)
                // この VC から遷移するのでボタンの押下受け付けは再開しない。
                // 遷移アニメーション中に処理が実行されることを防ぐ。
            } catch {
                // ユーザーに詳細なエラー情報は提示しないが、
                // デバッグ用にエラー情報を表示。
                logger.info("\(error)")
                throw error
            }
        }
    }
}
