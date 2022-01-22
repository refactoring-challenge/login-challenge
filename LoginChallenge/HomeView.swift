import SwiftUI
import Entities
import APIServices
import Logging

@MainActor
private let logger: Logger = .init(label: String(reflecting: HomeView.self))

@MainActor
struct HomeView: View {
    @State private var user: User?
    
    @State private var isReloading: Bool = false
    @State private var isLoggingOut: Bool = false
    
    @State private var presentsActivityIndocator: Bool = false
    @State private var presentsAuthenticationErrorAlert: Bool = false
    @State private var presentsNetworkErrorAlert: Bool = false
    @State private var presentsServerErrorAlert: Bool = false
    @State private var presentsSystemErrorAlert: Bool = false
    
    let dismiss: () async -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Color(UIColor.systemGray4))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 0) {
                        Text(user?.name ?? "User Name")
                            .font(.title3)
                            .redacted(reason: user?.name == nil ? .placeholder : [])
                        Text((user?.id.rawValue).map { id in "@\(id)" } ?? "@ididid")
                            .font(.body)
                            .foregroundColor(Color(UIColor.systemGray))
                            .redacted(reason: user?.id == nil ? .placeholder : [])
                    }
                    
                    let introduction = user?.introduction ?? "Introduction. Introduction. Introduction. Introduction. Introduction. Introduction."
                    if let attributedIntroduction = try? AttributedString(markdown: introduction) {
                        Text(attributedIntroduction)
                            .font(.body)
                            .redacted(reason: user?.introduction == nil ? .placeholder : [])
                    } else {
                        Text(introduction)
                            .font(.body)
                            .redacted(reason: user?.introduction == nil ? .placeholder : [])
                    }
                    
                    // リロードボタン
                    Button {
                        Task {
                            await loadUser()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isReloading)
                }
                .padding()
                
                Spacer()
                
                // ログアウトボタン
                Button("Logout") {
                    Task {
                        // 処理が二重に実行されるのを防ぐ。
                        if isLoggingOut { return }
                        
                        // 処理中はログアウトボタン押下を受け付けない。
                        isLoggingOut = false
                        
                        // Activity Indicator を表示。
                        presentsActivityIndocator = true
                        
                        // API を叩いて処理を実行。
                        await AuthService.logOut()
                        
                        // Activity Indicator を非表示に。
                        presentsActivityIndocator = false
                        
                        // LoginViewController に遷移。
                        await dismiss()
                        
                        // この View から遷移するのでボタンの押下受け付けは再開しない。
                        // 遷移アニメーション中に処理が実行されることを防ぐ。
                    }
                }
                .disabled(isLoggingOut)
                .padding(.bottom, 30)
            }
        }
        .alert(
            "認証エラー",
            isPresented: $presentsAuthenticationErrorAlert,
            actions: {
                Button("OK") {
                    Task {
                        // LoginViewController に遷移。
                        await dismiss()
                    }
                }
            },
            message: { Text("再度ログインして下さい。") }
        )
        .alert(
            "ネットワークエラー",
            isPresented: $presentsNetworkErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("通信に失敗しました。ネットワークの状態を確認して下さい。") }
        )
        .alert(
            "サーバーエラー",
            isPresented: $presentsServerErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("しばらくしてからもう一度お試し下さい。") }
        )
        .alert(
            "システムエラー",
            isPresented: $presentsSystemErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("エラーが発生しました。") }
        )
        .activityIndicatorCover(isPresented: presentsActivityIndocator)
        .task {
            await loadUser()
        }
    }
    
    private func loadUser() async {
        // 処理が二重に実行されるのを防ぐ。
        if isReloading { return }
        
        // 処理中はリロードボタン押下を受け付けない。
        isReloading = true
        
        do {
            // API を叩いて User を取得。
            let user = try await UserService.currentUser()
            
            // 取得した情報を View に反映。
            self.user = user
        } catch let error as AuthenticationError {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsAuthenticationErrorAlert = true
        } catch let error as NetworkError {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsNetworkErrorAlert = true
        } catch let error as ServerError {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsServerErrorAlert = true
        } catch {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsSystemErrorAlert = true
        }
        
        // 処理が完了したのでリロードボタン押下を再度受け付けるように。
        isReloading = false
    }
}
