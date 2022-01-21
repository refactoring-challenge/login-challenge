import UIKit

@MainActor
final class ActivityIndicatorViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified: return .black
            case .dark: return .white
            default: return .black
            }
        }
        .withAlphaComponent((1.0 - 182.0 / 255.0))
        
        let baseView: UIView = .init()
        baseView.translatesAutoresizingMaskIntoConstraints = false
        baseView.backgroundColor = .systemBackground
        baseView.layer.cornerRadius = 8
        baseView.layer.cornerCurve = .continuous
        view.addSubview(baseView)
        
        let indicatorView: UIActivityIndicatorView = .init(style: .large)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.startAnimating()
        baseView.addSubview(indicatorView)
        
        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            baseView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            baseView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicatorView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor, constant: padding),
            indicatorView.topAnchor.constraint(equalTo: baseView.topAnchor, constant: padding),
            baseView.trailingAnchor.constraint(equalTo: indicatorView.trailingAnchor, constant: padding),
            baseView.bottomAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: padding),
        ])
    }
}

