# Architecture

The app uses the MVVM pattern.

## Data Flow
Views observe ViewModels (ObservableObject / @Observable). ViewModels interact with Services (ApiServices, IPTVDataManager, etc.) which fetch from API or parse M3U.
