import UIKit

extension UIViewController {
    @MainActor
    func present(_ viewControllerToPresent: UIViewController, animated isAnimated: Bool) async {
        await withCheckedContinuation { continuation in
            present(viewControllerToPresent, animated: isAnimated) {
                continuation.resume()
            }
        }
    }
    
    @MainActor
    func dismiss(animated isAnimated: Bool) async {
        await withCheckedContinuation { continuation in
            dismiss(animated: isAnimated) {
                continuation.resume()
            }
        }
    }
}
