import SwiftUI
import AVKit
import AVFoundation

class PlayerUIView: UIView, AVPictureInPictureControllerDelegate {
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var pipController: AVPictureInPictureController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        print("\n\n--- [PiP DEBUG] APP ENTERED BACKGROUND ---")
        logCurrentPiPState()
    }
    
    @objc private func appWillEnterForeground() {
        print("\n\n--- [PiP DEBUG] APP ENTERED FOREGROUND ---")
        logCurrentPiPState()
    }
    
    func logCurrentPiPState() {
        print("PiP Supported: \(AVPictureInPictureController.isPictureInPictureSupported())")
        print("pipController instance exists: \(pipController != nil)")
        print("pipController possible: \(pipController?.isPictureInPicturePossible ?? false)")
        print("pipController active: \(pipController?.isPictureInPictureActive ?? false)")
        
        print("AudioSession Category: \(AVAudioSession.sharedInstance().category.rawValue)")
        print("AudioSession Mode: \(AVAudioSession.sharedInstance().mode.rawValue)")
        // Cannot easily check active state directly, but we assume it's active if no interruptions
        
        let player = playerLayer.player
        print("Player instance exists: \(player != nil)")
        print("Player timeControlStatus: \(player?.timeControlStatus.rawValue ?? -1) (0=paused, 1=waiting, 2=playing)")
        print("Player rate: \(player?.rate ?? -1)")
        print("PlayerItem status: \(player?.currentItem?.status.rawValue ?? -1) (0=unknown, 1=readyToPlay, 2=failed)")
        print("------------------------------------------\n")
    }
    
    func setupPip() {
        print("[PiP DEBUG] setupPip() called")
        if AVPictureInPictureController.isPictureInPictureSupported() {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                print("[PiP DEBUG] AVAudioSession set to .playback and active")
            } catch {
                print("[PiP DEBUG] Failed to set audio session for PIP: \(error)")
            }
            
            pipController = AVPictureInPictureController(playerLayer: playerLayer)
            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
            print("[PiP DEBUG] pipController initialized and canStartPictureInPictureAutomaticallyFromInline = true")
        } else {
            print("[PiP DEBUG] AVPictureInPictureController is not supported on this device/simulator.")
        }
    }
    
    func togglePip() {
        guard let pip = pipController else {
            print("[PiP DEBUG] togglePip() failed: pipController is nil")
            return
        }
        if pip.isPictureInPictureActive {
            print("[PiP DEBUG] Stopping PiP manually")
            pip.stopPictureInPicture()
        } else {
            print("[PiP DEBUG] Starting PiP manually. isPictureInPicturePossible: \(pip.isPictureInPicturePossible)")
            pip.startPictureInPicture()
        }
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP DEBUG DELEGATE] PIP Will Start")
    }
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP DEBUG DELEGATE] PIP Did Start")
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("[PiP DEBUG DELEGATE] PIP Failed to start: \(error.localizedDescription)")
    }
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP DEBUG DELEGATE] PIP Will Stop")
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[PiP DEBUG DELEGATE] PIP Did Stop")
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        print("[PiP DEBUG DELEGATE] PIP Restore User Interface requested")
        completionHandler(true)
    }
    
    deinit {
        print("[PiP DEBUG] PlayerUIView deinit")
        NotificationCenter.default.removeObserver(self)
    }
}

struct PremiumPlayerRepresentable: UIViewRepresentable {
    var player: AVPlayer
    var isAspectFill: Bool
    @Binding var triggerPip: Bool
    
    func makeUIView(context: Context) -> PlayerUIView {
        print("[PiP DEBUG] PremiumPlayerRepresentable makeUIView called")
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
        view.backgroundColor = .black
        view.setupPip()
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        print("[PiP DEBUG] PremiumPlayerRepresentable updateUIView called")
        if uiView.playerLayer.player !== player {
            print("[PiP DEBUG] Updating player instance in playerLayer")
            uiView.playerLayer.player = player
        }
        
        let targetGravity: AVLayerVideoGravity = isAspectFill ? .resizeAspectFill : .resizeAspect
        if uiView.playerLayer.videoGravity != targetGravity {
            uiView.playerLayer.videoGravity = targetGravity
        }
        
        if triggerPip {
            DispatchQueue.main.async {
                print("[PiP DEBUG] Trigger PiP explicitly invoked via Binding")
                uiView.togglePip()
                self.triggerPip = false
            }
        }
    }
    
    static func dismantleUIView(_ uiView: PlayerUIView, coordinator: ()) {
        print("[PiP DEBUG] PremiumPlayerRepresentable dismantleUIView called")
    }
}
