import SwiftUI
import MobileVLCKit
import AVFoundation

class VLCPlayerUIView: UIView, VLCMediaPlayerDelegate {
    let internalPlayer: VLCMediaPlayer
    var isAspectFill: Bool = false {
        didSet {
            updateGravity()
        }
    }
    
    init(player: VLCMediaPlayer) {
        self.internalPlayer = player
        super.init(frame: .zero)
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer() {
        internalPlayer.drawable = self
        updateGravity()
    }
    
    private func updateGravity() {
        if isAspectFill {
            internalPlayer.videoCropGeometry = UnsafeMutablePointer<Int8>(mutating: "16:9".cString(using: .utf8))
        } else {
            internalPlayer.videoCropGeometry = nil
        }
    }
}

struct VLCPlayerRepresentable: UIViewRepresentable {
    var player: VLCMediaPlayer
    var isAspectFill: Bool
    
    func makeUIView(context: Context) -> VLCPlayerUIView {
        let view = VLCPlayerUIView(player: player)
        view.isAspectFill = isAspectFill
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: VLCPlayerUIView, context: Context) {
        if player.drawable as? UIView != uiView {
            player.drawable = uiView
        }
        if uiView.isAspectFill != isAspectFill {
            uiView.isAspectFill = isAspectFill
        }
    }
}
