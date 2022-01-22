import SwiftUI

extension View {
    public func activityIndicatorCover(isPresented: Bool) -> some View {
        modifier(ActivityIndicatorCoverModifier(isPresented: isPresented))
    }
}

private struct ActivityIndicatorCoverModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        ActivityIndicatorCoverView(isPresented: isPresented, content: content)
    }
}

private struct ActivityIndicatorCoverView<Content: View>: UIViewControllerRepresentable {
    let isPresented: Bool
    let content: Content
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        UIHostingController<Content>(rootView: content)
    }
    
    func updateUIViewController(_ viewController: UIHostingController<Content>, context: Context) {
        if isPresented {
            guard viewController.presentedViewController == nil else { return }
            
            let indicatorViewController: ActivityIndicatorViewController = .init()
            indicatorViewController.modalPresentationStyle = .overFullScreen
            indicatorViewController.modalTransitionStyle = .crossDissolve
            
            context.coordinator.presentedViewController = indicatorViewController
            viewController.present(indicatorViewController, animated: true, completion: nil)
        } else {
            guard let indicatorViewController = viewController.presentedViewController, indicatorViewController === context.coordinator.presentedViewController else { return }
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator {
        fileprivate var presentedViewController: UIViewController?
    }
}

