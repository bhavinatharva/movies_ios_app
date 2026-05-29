import SwiftUI
import AVKit

class PlayerUIView: UIView {
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var pipController: AVPictureInPictureController?
    
    func setupPip() {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer)
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
    }
    
    func togglePip() {
        guard let pip = pipController else { return }
        if pip.isPictureInPictureActive {
            pip.stopPictureInPicture()
        } else {
            pip.startPictureInPicture()
        }
    }
}

struct PremiumPlayerRepresentable: UIViewRepresentable {
    var player: AVPlayer
    var isAspectFill: Bool
    @Binding var triggerPip: Bool
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
        view.backgroundColor = .black
        view.setupPip()
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
        
        if triggerPip {
            DispatchQueue.main.async {
                uiView.togglePip()
                self.triggerPip = false
            }
        }
    }
}
