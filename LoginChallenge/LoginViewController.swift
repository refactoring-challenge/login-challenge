import UIKit
import Entities
import SwiftUI

@MainActor
final class LoginViewController: UIViewController {
    @IBOutlet private var idField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    private let loginViewStateManager = LoginViewStateManagerImpl(
        validationService: ValidationServiceImpl()
    )
    private let loginInteractor = LoginInteractorImpl()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // VC を表示する前に View の状態のアップデートし、状態の不整合を防ぐ。
        // loginButton は ID およびパスワードが空でない場合だけ有効。
        let expectState = loginViewStateManager.viewWillAppear(id: idField.text ?? "", password: passwordField.text ?? "")
        loginButton.isEnabled = expectState.loginButtonIsEnabled
        idField.isEnabled = expectState.idFieldIsEnabled
        passwordField.isEnabled = expectState.passwordFieldIsEnabled
    }
    
    // ログインボタンが押されたときにログイン処理を実行。
    @IBAction private func loginButtonPressed(_ sender: UIButton) {
        Task {
            // Task.init で 1 サイクル遅れるので、
            // その間に再度ログインボタンが押された場合に
            // 処理が二重に実行されるのを防ぐ。
            guard loginButton.isEnabled else { return }
            
            // Task.init で 1 サイクル遅れる間に、
            // 本来処理を実行すべきでない不正な状態になっていた場合に
            // 処理が実行されるのを防ぐ。
            guard let id = idField.text, let password = passwordField.text else { return }

            // 処理中は入力とボタン押下を受け付けない。
            let expectedState = loginViewStateManager.processingLoginButtonPressed()
            idField.isEnabled = expectedState.idFieldIsEnabled
            passwordField.isEnabled = expectedState.passwordFieldIsEnabled
            loginButton.isEnabled = expectedState.loginButtonIsEnabled

            await showActivityIndicator()
            await executeLogin(id: id, password: password)
        }
    }

    private func showActivityIndicator() async -> Void {
        Task {
            // Activity Indicator を表示。
            let activityIndicatorViewController: ActivityIndicatorViewController = .init()
            activityIndicatorViewController.modalPresentationStyle = .overFullScreen
            activityIndicatorViewController.modalTransitionStyle = .crossDissolve
            await present(activityIndicatorViewController, animated: true)
        }
    }

    private func executeLogin(id: String, password: String) async -> Void {
        Task {
            do {
                // API を叩いて処理を実行。
                try await loginInteractor.logInWith(id: id, password: password)

                // Activity Indicator を非表示に。
                await dismiss(animated: true)

                await moveToHomeView()
                // この VC から遷移するのでボタンの押下受け付けは再開しない。
                // 遷移アニメーション中に処理が実行されることを防ぐ。
            } catch {
                // Activity Indicator を非表示に。
                await dismiss(animated: true)

                // 入力とログインボタン押下を再度受け付けるように。
                let expectedState = loginViewStateManager.whenLogInWithFailed()
                idField.isEnabled = expectedState.idFieldIsEnabled
                passwordField.isEnabled = expectedState.passwordFieldIsEnabled
                loginButton.isEnabled = expectedState.loginButtonIsEnabled

                await present(AlertType.toAlertController(error: error), animated: true)
            }
        }
    }

    private func moveToHomeView() async -> Void {
        Task {
            // HomeView に遷移。
            let destination = UIHostingController(rootView: HomeView(dismiss: { [weak self] in
                await self?.dismiss(animated: true)
            }))
            destination.modalPresentationStyle = .fullScreen
            destination.modalTransitionStyle = .flipHorizontal
            await present(destination, animated: true)
        }
    }

    // ID およびパスワードのテキストが変更されたときに View の状態を更新。
    @IBAction private func inputFieldValueChanged(sender: UITextField) {
        // loginButton は ID およびパスワードが空でない場合だけ有効。
        let expectedState = loginViewStateManager.inputFieldValueChanged(
            id: idField.text ?? "",
            password: passwordField.text ?? ""
        )
        loginButton.isEnabled = expectedState.loginButtonIsEnabled
    }
}

enum AlertType {
    static func toAlertController(error: Error) -> UIAlertController {
        switch error {
        case is LoginError:
            // アラートでエラー情報を表示。
            // ユーザーには不必要に詳細なエラー情報は提示しない。
            let alertController: UIAlertController = .init(
                title: "ログインエラー",
                message: "IDまたはパスワードが正しくありません。",
                preferredStyle: .alert
            )
            alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
            return alertController
        case is NetworkError:

            let alertController: UIAlertController = .init(
                title: "ネットワークエラー",
                message: "通信に失敗しました。ネットワークの状態を確認して下さい。",
                preferredStyle: .alert
            )
            alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
            return alertController
        case is ServerError:
            let alertController: UIAlertController = .init(
                title: "サーバーエラー",
                message: "しばらくしてからもう一度お試し下さい。",
                preferredStyle: .alert
            )
            alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
            return alertController
        default:
            let alertController: UIAlertController = .init(
                title: "システムエラー",
                message: "エラーが発生しました。",
                preferredStyle: .alert
            )
            alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
            return alertController
        }
    }
}

protocol ValidationService {
    func login(id: String, password: String) -> Bool
    func inputFieldValueChanged(id: String, password: String) -> Bool
}

final class ValidationServiceImpl: ValidationService {
    func login(id: String, password: String) -> Bool {
        !(id.isEmpty || password.isEmpty)
    }

    func inputFieldValueChanged(id: String, password: String) -> Bool {
        !(id.isEmpty || password.isEmpty)
    }
}

final class LoginViewStateManagerImpl {
    private let validationService: ValidationService
    init(validationService: ValidationService) {
        self.validationService = validationService
    }

    func viewWillAppear(id: String, password: String) -> LoginViewState {
        LoginViewState(
            idFieldIsEnabled: true,
            passwordFieldIsEnabled: true,
            loginButtonIsEnabled: validationService.login(id: id, password: password)
        )
    }

    func inputFieldValueChanged(id: String, password: String) -> LoginViewState {
        LoginViewState(
            idFieldIsEnabled: true, // TODO: ここでは意味を持たないので要Refactoring
            passwordFieldIsEnabled: true, // TODO: ここでは意味を持たないので要Refactoring
            loginButtonIsEnabled: validationService.inputFieldValueChanged(id: id, password: password)
        )
    }

    func processingLoginButtonPressed() -> LoginViewState {
        LoginViewState(
            idFieldIsEnabled: false,
            passwordFieldIsEnabled: false,
            loginButtonIsEnabled: false
        )
    }

    func whenLogInWithFailed() -> LoginViewState {
        LoginViewState(
            idFieldIsEnabled: false,
            passwordFieldIsEnabled: false,
            loginButtonIsEnabled: false
        )
    }

    struct LoginViewState {
        let idFieldIsEnabled: Bool
        let passwordFieldIsEnabled: Bool
        let loginButtonIsEnabled: Bool
    }
}
