# Player

- Custom player implementation using AVPlayer (`StreamingPlayerView` / `PremiumPlayerRepresentable`).
- Supported on both iOS and tvOS.
- On tvOS, player is optimized for Siri Remote navigation and integrates with Apple TV audio routing.
- YouTube trailer integration via `YoutubePlayer` (supported on iOS; gracefully handled on tvOS where WebKit is unavailable).
- MobileVLCKit fallback on iOS, with clean stubs/TVVLCKit support on tvOS.
