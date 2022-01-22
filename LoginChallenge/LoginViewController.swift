import UIKit
import Entities
import APIServices
import Logging
import SwiftUI

@MainActor
final class LoginViewController: UIViewController {
    @IBOutlet private var idField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    
    // String(reflecting:) はモジュール名付きの型名を取得するため。
    private let logger: Logger = .init(label: String(reflecting: LoginViewController.self))
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // VC を表示する前に View の状態のアップデートし、状態の不整合を防ぐ。
        // loginButton は ID およびパスワードが空でない場合だけ有効。
        loginButton.isEnabled = !(
            idField.text?.isEmpty ?? true
            || passwordField.text?.isEmpty ?? true
        )
        idField.isEnabled = true
        passwordField.isEnabled = true
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
            idField.isEnabled = false
            passwordField.isEnabled = false
            loginButton.isEnabled = false
            
            // Activity Indicator を表示。
            let activityIndicatorViewController: ActivityIndicatorViewController = .init()
            activityIndicatorViewController.modalPresentationStyle = .overFullScreen
            activityIndicatorViewController.modalTransitionStyle = .crossDissolve
            await present(activityIndicatorViewController, animated: true)
            
            do {
                // API を叩いて処理を実行。
                try await AuthService.logInWith(id: id, password: password)
                
                // Activity Indicator を非表示に。
                await dismiss(animated: true)

                // HomeView に遷移。
                let destination = UIHostingController(rootView: HomeView(dismiss: { [weak self] in
                    await self?.dismiss(animated: true)
                }))
                destination.modalPresentationStyle = .fullScreen
                destination.modalTransitionStyle = .flipHorizontal
                await present(destination, animated: true)
                
                // HomeViewController に遷移。
                //performSegue(withIdentifier: "Login", sender: nil)
                
                // この VC から遷移するのでボタンの押下受け付けは再開しない。
                // 遷移アニメーション中に処理が実行されることを防ぐ。
            } catch let error as LoginError {
                // ユーザーに詳細なエラー情報は提示しないが、
                // デバッグ用にエラー情報を表示。
                logger.info("\(error)")
                
                // Activity Indicator を非表示に。
                await dismiss(animated: true)
                
                // 入力とログインボタン押下を再度受け付けるように。
                idField.isEnabled = true
                passwordField.isEnabled = true
                loginButton.isEnabled = true
                
                // アラートでエラー情報を表示。
                // ユーザーには不必要に詳細なエラー情報は提示しない。
                let alertController: UIAlertController = .init(
                    title: "ログインエラー",
                    message: "IDまたはパスワードが正しくありません。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                await present(alertController, animated: true)
            } catch let error as NetworkError {
                logger.info("\(error)")
                
                await dismiss(animated: true)
                
                idField.isEnabled = true
                passwordField.isEnabled = true
                loginButton.isEnabled = true
                
                let alertController: UIAlertController = .init(
                    title: "ネットワークエラー",
                    message: "通信に失敗しました。ネットワークの状態を確認して下さい。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                await present(alertController, animated: true)
            } catch let error as ServerError {
                logger.info("\(error)")
                
                await dismiss(animated: true)
                
                idField.isEnabled = true
                passwordField.isEnabled = true
                loginButton.isEnabled = true
                
                let alertController: UIAlertController = .init(
                    title: "サーバーエラー",
                    message: "しばらくしてからもう一度お試し下さい。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                await present(alertController, animated: true)
            } catch {
                logger.info("\(error)")
                
                await dismiss(animated: true)
                
                idField.isEnabled = true
                passwordField.isEnabled = true
                loginButton.isEnabled = true
                
                let alertController: UIAlertController = .init(
                    title: "システムエラー",
                    message: "エラーが発生しました。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                await present(alertController, animated: true)
            }
        }
    }
    
    // ID およびパスワードのテキストが変更されたときに View の状態を更新。
    @IBAction private func inputFieldValueChanged(sender: UITextField) {
        // loginButton は ID およびパスワードが空でない場合だけ有効。
        loginButton.isEnabled = !(
            idField.text?.isEmpty ?? true
            || passwordField.text?.isEmpty ?? true
        )
    }
}
