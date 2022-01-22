import UIKit
import Entities
import APIServices
import Logging

@MainActor
final class HomeViewController: UIViewController {
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var idLabel: UILabel!
    @IBOutlet private var introductionLabel: UILabel!
    
    @IBOutlet private var reloadButton: UIButton!
    @IBOutlet private var logoutButton: UIButton!
    
    private var user: User?
    
    private let logger: Logger = .init(label: String(reflecting: HomeViewController.self))
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // VC を表示する前に View の状態のアップデートし、状態の不整合を防ぐ。
        nameLabel.text = user?.name
        idLabel.text = (user?.id).map { id in "@\(id.rawValue)" }
        if let user = self.user, let introduction = try? AttributedString(markdown: user.introduction) {
            introductionLabel.attributedText = NSAttributedString(introduction)
        } else {
            introductionLabel.text = user?.introduction
        }
        reloadButton.isEnabled = true
        
        // User のロードを開始。
        loadUser()
    }
    
    // リロードボタンが押されたときに User のロードを実行。
    @IBAction private func reloadButtonPressed(sender: UIButton) {
        loadUser()
    }
    
    private func loadUser() {
        Task {
            // Task.init で 1 サイクル遅れるので、
            // その間に再度リロードボタンが押された場合に
            // 処理が二重に実行されるのを防ぐ。
            guard reloadButton.isEnabled else { return }
            
            // 処理中はリロードボタン押下を受け付けない。
            reloadButton.isEnabled = false
            
            do {
                // API を叩いて User を取得。
                let user = try await UserService.currentUser()
                self.user = user
                
                // 取得した情報を View に反映。
                nameLabel.text = user.name
                idLabel.text = "@\(user.id.rawValue)"
                if let introduction = try? AttributedString(markdown: user.introduction) {
                    introductionLabel.attributedText = NSAttributedString(introduction)
                } else {
                    introductionLabel.text = user.introduction
                }
            } catch let error as AuthenticationError {
                logger.info("\(error)")
                
                let alertController: UIAlertController = .init(
                    title: "認証エラー",
                    message: "再度ログインして下さい。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "OK", style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    Task {
                        // LoginViewController に遷移。
                        await self.presentingViewController?.dismiss(animated: true)
                    }
                }))
                await present(alertController, animated: true)
            } catch let error as NetworkError {
                logger.info("\(error)")
                
                let alertController: UIAlertController = .init(
                    title: "ネットワークエラー",
                    message: "通信に失敗しました。ネットワークの状態を確認して下さい。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                await present(alertController, animated: true)
            } catch let error as ServerError {
                logger.info("\(error)")
                
                let alertController: UIAlertController = .init(
                    title: "サーバーエラー",
                    message: "しばらくしてからもう一度お試し下さい。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                await present(alertController, animated: true)
            } catch {
                logger.info("\(error)")
                
                let alertController: UIAlertController = .init(
                    title: "システムエラー",
                    message: "エラーが発生しました。",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                await present(alertController, animated: true)
            }
            
            // 処理が完了したのでリロードボタン押下を再度受け付けるように。
            reloadButton.isEnabled = true
        }
    }
    
    // ログアウトボタンが押されたときにログアウト処理を実行。
    @IBAction private func logoutButtonPressed(sender: UIButton) {
        Task {
            // Task.init で 1 サイクル遅れるので、
            // その間に再度ログアウトボタンが押された場合に
            // 処理が二重に実行されるのを防ぐ。
            guard logoutButton.isEnabled else { return }
            
            // 処理中はログアウトボタン押下を受け付けない。
            logoutButton.isEnabled = false
            
            // Activity Indicator を表示。
            let activityIndicatorViewController: ActivityIndicatorViewController = .init()
            activityIndicatorViewController.modalPresentationStyle = .overFullScreen
            activityIndicatorViewController.modalTransitionStyle = .crossDissolve
            await present(activityIndicatorViewController, animated: true)

            // API を叩いて処理を実行。
            await AuthService.logOut()
            
            // Activity Indicator を非表示に。
            await dismiss(animated: true)
            
            // LoginViewController に遷移。
            await presentingViewController?.dismiss(animated: true)
            
            // この VC から遷移するのでボタンの押下受け付けは再開しない。
            // 遷移アニメーション中に処理が実行されることを防ぐ。
        }
    }
}
