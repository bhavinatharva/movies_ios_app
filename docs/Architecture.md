# Architecture

The app uses the MVVM pattern with a shared core across iOS and tvOS.

## Targets
- **MoviesApp (iOS)**: iPhone and iPad target with touch controls, sidebar/tab navigation, and haptic feedback.
- **MoviesAppTV (tvOS)**: Apple TV target with Siri Remote focus engine integration, 16:9 large-screen navigation, and native top TabView.

## Data Flow
Views observe ViewModels (ObservableObject / @Observable). ViewModels interact with Services (`ApiServices`, `IPTVDataManager`, `IPTVSyncManager`, etc.) which fetch from API or parse M3U. Both targets share 100% of models, parsing, networking, caching, and database logic.
