import SwiftUI

struct GestureController: View {
    let streamType: MediaType
    let onDoubleTapLeft: () -> Void
    let onDoubleTapRight: () -> Void
    let onSingleTap: () -> Void
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Zone
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onDoubleTapLeft()
                }
                .onTapGesture {
                    onSingleTap()
                }
            
            // Right Zone
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onDoubleTapRight()
                }
                .onTapGesture {
                    onSingleTap()
                }
        }
        .ignoresSafeArea()
        .gesture(
            streamType == .liveTV ? DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if abs(value.translation.height) > abs(value.translation.width) {
                        if value.translation.height < 0 {
                            onSwipeUp()
                        } else {
                            onSwipeDown()
                        }
                    }
                }
            : nil
        )
    }
}
