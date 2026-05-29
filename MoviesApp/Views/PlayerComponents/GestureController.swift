import SwiftUI
import MediaPlayer
import AVFoundation

struct GestureController: View {
    let streamType: MediaType
    let onDoubleTapLeft: () -> Void
    let onDoubleTapRight: () -> Void
    let onSingleTap: () -> Void
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    var onSeekDrag: ((CGFloat) -> Void)? = nil
    var onSeekEnd: (() -> Void)? = nil
    
    @State private var startBrightness: CGFloat = 0
    @State private var startVolume: Float = 0
    @State private var volumeSlider: UISlider? = nil
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left Zone (Brightness)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, perform: onDoubleTapLeft)
                    .onTapGesture(perform: onSingleTap)
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                if abs(value.translation.height) > abs(value.translation.width) {
                                    let delta = -value.translation.height / geo.size.height
                                    UIScreen.main.brightness = max(0, min(1, startBrightness + delta))
                                } else if streamType != .liveTV {
                                    onSeekDrag?(value.translation.width)
                                }
                            }
                            .onEnded { value in
                                startBrightness = UIScreen.main.brightness
                                if abs(value.translation.width) > abs(value.translation.height) && streamType != .liveTV {
                                    onSeekEnd?()
                                } else if streamType == .liveTV && value.translation.height < -50 {
                                    onSwipeUp()
                                } else if streamType == .liveTV && value.translation.height > 50 {
                                    onSwipeDown()
                                }
                            }
                    )
                
                // Right Zone (Volume)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, perform: onDoubleTapRight)
                    .onTapGesture(perform: onSingleTap)
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                if abs(value.translation.height) > abs(value.translation.width) {
                                    let delta = Float(-value.translation.height / geo.size.height)
                                    if let slider = volumeSlider {
                                        slider.value = max(0, min(1, startVolume + delta))
                                    }
                                } else if streamType != .liveTV {
                                    onSeekDrag?(value.translation.width)
                                }
                            }
                            .onEnded { value in
                                startVolume = volumeSlider?.value ?? AVAudioSession.sharedInstance().outputVolume
                                if abs(value.translation.width) > abs(value.translation.height) && streamType != .liveTV {
                                    onSeekEnd?()
                                } else if streamType == .liveTV && value.translation.height < -50 {
                                    onSwipeUp()
                                } else if streamType == .liveTV && value.translation.height > 50 {
                                    onSwipeDown()
                                }
                            }
                    )
            }
            .onAppear {
                startBrightness = UIScreen.main.brightness
                setupVolumeView()
            }
        }
        .ignoresSafeArea()
    }
    
    private func setupVolumeView() {
        let view = MPVolumeView()
        for subview in view.subviews {
            if let slider = subview as? UISlider {
                volumeSlider = slider
                startVolume = slider.value
                break
            }
        }
    }
}
