import SwiftUI
import AVKit

struct PremiumPlayerRepresentable: UIViewControllerRepresentable {
    var player: AVPlayer
    var isAspectFill: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
        controller.view.backgroundColor = .black
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
    }
}
