import SwiftUI

@MainActor
struct HomeView: View {
    @StateObject var vm: HomeViewModel = HomeViewModel()
    
    let dismiss: () async -> Void // TODO: こいつどうにかする
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Color(UIColor.systemGray4))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 0) {
                        Text(vm.user?.name ?? "User Name")
                            .font(.title3)
                            .redacted(reason: vm.user?.name == nil ? .placeholder : [])
                        Text((vm.user?.id.rawValue).map { id in "@\(id)" } ?? "@ididid")
                            .font(.body)
                            .foregroundColor(Color(UIColor.systemGray))
                            .redacted(reason: vm.user?.id == nil ? .placeholder : [])
                    }
                    
                    let introduction = vm.user?.introduction ?? "Introduction. Introduction. Introduction. Introduction. Introduction. Introduction."
                    if let attributedIntroduction = try? AttributedString(markdown: introduction) {
                        Text(attributedIntroduction)
                            .font(.body)
                            .redacted(reason: vm.user?.introduction == nil ? .placeholder : [])
                    } else {
                        Text(introduction)
                            .font(.body)
                            .redacted(reason: vm.user?.introduction == nil ? .placeholder : [])
                    }
                    
                    reloadButton
                }
                .padding()
                
                Spacer()
                
                // ログアウトボタン
                logoutButton
                .padding(.bottom, 30)
            }
        }
        .activityIndicatorCover(isPresented: vm.presentsActivityIndicator)
        .task {
            await vm.loadUser()
        }
        .alert(isPresented: $vm.presentsActivityIndicator) {
            vm.alertType.toAlert(action: {
                Task {
                    // LoginViewController に遷移。
                    await dismiss()
                }
            })
        }
    }

    private var reloadButton: some View {
        // リロードボタン
        Button {
            Task {
                await vm.loadUser()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(vm.isReloading)
    }

    private var logoutButton: some View {
        // ログアウトボタン
        Button("Logout") {
            Task {
                await vm.logout()
                // LoginViewController に遷移。
                await dismiss()

                // この View から遷移するのでボタンの押下受け付けは再開しない。
                // 遷移アニメーション中に処理が実行されることを防ぐ。
            }
        }
        .disabled(vm.isLoggingOut)
    }
}
