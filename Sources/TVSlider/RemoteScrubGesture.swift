#if os(tvOS)
import SwiftUI
import UIKit

/// Reports horizontal pans on the Siri Remote touch surface while `isActive`.
///
/// SwiftUI on tvOS has no API for continuous touch-surface input, so this
/// installs a `UIPanGestureRecognizer` for indirect touches on the window
/// and forwards it only while the owning control is focused.
struct RemoteScrubGesture: UIViewRepresentable {
    enum Phase { case began, changed, ended }

    var isActive: Bool
    /// Translation is a fraction of the window width (positive = right).
    var onScrub: (Phase, Double) -> Void

    func makeUIView(context: Context) -> ScrubView {
        let view = ScrubView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: ScrubView, context: Context) {
        view.isActive = isActive
        view.onScrub = onScrub
    }

    static func dismantleUIView(_ view: ScrubView, coordinator: ()) {
        view.detach()
    }

    final class ScrubView: UIView {
        var isActive = false {
            didSet {
                if !isActive, isScrubbing {
                    isScrubbing = false
                    onScrub?(.ended, 0)
                }
            }
        }
        var onScrub: ((Phase, Double) -> Void)?
        private var isScrubbing = false
        private weak var attachedWindow: UIWindow?
        private lazy var recognizer: UIPanGestureRecognizer = {
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            recognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delegate = delegateProxy
            return recognizer
        }()
        private lazy var delegateProxy = DelegateProxy(owner: self)

        override func didMoveToWindow() {
            super.didMoveToWindow()
            detach()
            if let window {
                window.addGestureRecognizer(recognizer)
                attachedWindow = window
            }
        }

        func detach() {
            attachedWindow?.removeGestureRecognizer(recognizer)
            attachedWindow = nil
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let window = recognizer.view else { return }
            let width = max(1, window.bounds.width)
            let translation = recognizer.translation(in: window)
            switch recognizer.state {
            case .began:
                guard isActive else { return }
                isScrubbing = true
                onScrub?(.began, 0)
            case .changed:
                guard isScrubbing else { return }
                onScrub?(.changed, Double(translation.x / width))
            case .ended, .cancelled, .failed:
                guard isScrubbing else { return }
                isScrubbing = false
                onScrub?(.ended, Double(translation.x / width))
            default:
                break
            }
        }

        /// Only begin for predominantly horizontal pans while active, so
        /// vertical swipes still move focus normally.
        final class DelegateProxy: NSObject, UIGestureRecognizerDelegate {
            weak var owner: ScrubView?
            init(owner: ScrubView) { self.owner = owner }

            func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
                guard let owner, owner.isActive, let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
                let velocity = pan.velocity(in: pan.view)
                return abs(velocity.x) > abs(velocity.y)
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
                true
            }
        }
    }
}
#endif
