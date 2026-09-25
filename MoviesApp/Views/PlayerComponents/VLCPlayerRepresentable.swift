import SwiftUI
#if canImport(TVVLCKit)
import TVVLCKit
#elseif canImport(MobileVLCKit)
import MobileVLCKit
#endif

#if canImport(TVVLCKit) || canImport(MobileVLCKit)
struct VLCPlayerRepresentable: UIViewRepresentable {
    var player: VLCMediaPlayer
    var isAspectFill: Bool

    func makeUIView(context: Context) -> VLCPlayerUIView {
        return VLCPlayerUIView(player: player, isAspectFill: isAspectFill)
    }

    func updateUIView(_ uiView: VLCPlayerUIView, context: Context) {
        uiView.isAspectFill = isAspectFill
        if player.drawable as? UIView != uiView {
            player.drawable = uiView
        }
    }
}

class VLCPlayerUIView: UIView {
    let internalPlayer: VLCMediaPlayer
    var isAspectFill: Bool = false {
        didSet {
            updateGravity()
        }
    }

    init(player: VLCMediaPlayer, isAspectFill: Bool) {
        self.internalPlayer = player
        self.isAspectFill = isAspectFill
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
            internalPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
        } else {
            internalPlayer.videoAspectRatio = nil
        }
    }
}
#else
struct VLCPlayerRepresentable: View {
    var player: Any
    var isAspectFill: Bool
    
    var body: some View {
        Text("VLCKit not available")
    }
}
#endif
