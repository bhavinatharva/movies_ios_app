import SwiftUI
import MediaPlayer
import AVFoundation

struct GestureController: View {
    let streamType: MediaType
    let onDoubleTap: () -> Void
    let onSingleTap: () -> Void
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    var onSeekDrag: ((CGFloat) -> Void)? = nil
    var onSeekEnd: (() -> Void)? = nil
    
    @State private var startBrightness: CGFloat = 0
    @State private var startVolume: Float = 0
    @State private var volumeSlider: UISlider? = nil
    
    // Zapping threshold
    private let zapThreshold: CGFloat = 80
    
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2, perform: {
                    onDoubleTap()
                })
                .onTapGesture(perform: onSingleTap)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            let isVertical = abs(value.translation.height) > abs(value.translation.width)
                            let isLeftEdge = value.startLocation.x < geo.size.width * 0.3
                            let isRightEdge = value.startLocation.x > geo.size.width * 0.7
                            
                            if isVertical {
                                if isLeftEdge {
                                    // Brightness
                                    let delta = -value.translation.height / geo.size.height
                                    UIScreen.main.brightness = max(0, min(1, startBrightness + delta))
                                } else if isRightEdge {
                                    // Volume
                                    let delta = Float(-value.translation.height / geo.size.height)
                                    if let slider = volumeSlider {
                                        slider.value = max(0, min(1, startVolume + delta))
                                    }
                                }
                            } else {
                                // Horizontal
                                if streamType != .liveTV {
                                    onSeekDrag?(value.translation.width)
                                }
                            }
                        }
                        .onEnded { value in
                            startBrightness = UIScreen.main.brightness
                            startVolume = volumeSlider?.value ?? AVAudioSession.sharedInstance().outputVolume
                            
                            let isVertical = abs(value.translation.height) > abs(value.translation.width)
                            if !isVertical {
                                if streamType == .liveTV {
                                    if value.translation.width < -zapThreshold {
                                        onSwipeLeft()
                                    } else if value.translation.width > zapThreshold {
                                        onSwipeRight()
                                    }
                                } else {
                                    onSeekEnd?()
                                }
                            }
                        }
                )
        }
        .ignoresSafeArea()
        .onAppear {
            startBrightness = UIScreen.main.brightness
            setupVolumeView()
        }
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
