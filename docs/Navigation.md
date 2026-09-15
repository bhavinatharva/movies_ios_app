# Navigation

- **Entry Point**: `MoviesAppApp` -> `ContentView`
- **Main Navigation**: `MainTabView`
  - **iPhone (Compact)**: Translucent bottom `TabView` with blur effect and dynamic IPTV tabs (Home, Recent, Live TV, Movies, Series).
  - **iPad (Regular)**: Persistent glassmorphic native `SidebarView` split navigation with active tab indicator, quick actions (Search, Settings), and active playlist status.
- **Adaptive Split Layouts**: `LiveTVView`, `VODMoviesView`, and `SeriesView` feature integrated category selector sidebars on iPad regular horizontal size class, while preserving category filter sheets on iPhone compact size class.
- **Category Browsing**:
  - **iPad**: Integrated sticky category selector panel directly beside the content grids in Live TV, Movies, and Series without opening modal sheets.
  - **iPhone**: Modal bottom sheet via `categoryFilter` sheet.
