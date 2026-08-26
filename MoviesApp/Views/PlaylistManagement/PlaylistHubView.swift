import SwiftUI

struct PlaylistHubView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    private let playlistManager = PlaylistManager.shared
    
    @State private var playlists: [Playlist] = []
    @State private var isShowingAddWizard = false
    @State private var isActivating = false
    @State private var isRefreshing = false
    @State private var searchText = ""
    
    var filteredPlaylists: [Playlist] {
        if searchText.isEmpty {
            return playlists
        } else {
            return playlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.url.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            // Liquid Glass Animated Hero Background
            LinearGradient(
                colors: [Color.appBackground, Color.accentColor.opacity(0.15), Color.appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Floating Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search Playlists, URL...", text: $searchText)
                        .foregroundColor(.primary)
                }
                .padding(12)
                .liquidGlass(cornerRadius: 15, blurRadius: 10, opacity: 0.8)
                .padding(.horizontal)
                .padding(.top, 8)
                
                if playlists.isEmpty {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Hero Section for Active Playlist
                            if let active = playlists.first(where: { $0.isDefault }) {
                                activePlaylistHero(active)
                            }
                            
                            // All Playlists
                            VStack(alignment: .leading, spacing: 16) {
                                Text("All Playlists")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                ForEach(filteredPlaylists) { playlist in
                                    PlaylistCardView(
                                        playlist: playlist,
                                        isActive: playlist.isDefault,
                                        onActivate: { activate(playlist: playlist) },
                                        onDelete: { delete(playlist: playlist) },
                                        onRefresh: { refreshCurrentContent() }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.bottom, 100) // Space for FAB
                    }
                }
            }
            
            // Premium Floating Action Button (FAB)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        isShowingAddWizard = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Playlist")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                                .shadow(color: Color.accentColor.opacity(0.45), radius: 10, x: 0, y: 5)
                        )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Playlist Hub")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            refreshPlaylists()
        }
        .fullScreenCover(isPresented: $isShowingAddWizard) {
            AddPlaylistWizardView {
                refreshPlaylists()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    isShowingAddWizard = true
                }) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .overlay {
            if isActivating || isRefreshing {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text(isActivating ? "Activating Playlist..." : "Refreshing Content...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(Color.gray.opacity(0.2).blur(radius: 10))
                    .cornerRadius(20)
                }
            }
        }
    }
    
    // MARK: - Subviews
    private func activePlaylistHero(_ playlist: Playlist) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ACTIVE PLAYLIST")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.accentColor)
                        .tracking(1.5)
                    
                    Text(playlist.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Text(playlist.url)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            
            Divider().background(Color.secondary.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("STATUS")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Connected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("CONTENT")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("— Live | — VOD")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(24)
        .liquidGlass(cornerRadius: 24, blurRadius: 20, opacity: 0.9)
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv.badge.wifi")
                .font(.system(size: 80))
                .foregroundColor(.accentColor.opacity(0.8))
                .shadow(color: .accentColor.opacity(0.4), radius: 20)
            
            Text("Welcome to IPTV Hub")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your premium streaming experience starts here. Tap below to add an M3U or Xtream Codes playlist.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                isShowingAddWizard = true
            }) {
                Text("Import Playlist")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(25)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 10)
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Actions
    private func refreshPlaylists() {
        playlists = playlistManager.fetchAllPlaylists()
        hasDefaultPlaylist = !playlists.isEmpty
    }
    
    private func activate(playlist: Playlist) {
        guard !playlist.isDefault else { return }
        isActivating = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        playlistManager.setDefault(playlist)
        refreshPlaylists()
        Task {
            await IPTVDataManager.shared.refreshContent(clearFirst: true)
            isActivating = false
        }
    }
    
    private func delete(playlist: Playlist) {
        playlistManager.deletePlaylist(playlist)
        refreshPlaylists()
        Task {
            await IPTVDataManager.shared.refreshContent()
        }
    }
    
    private func refreshCurrentContent() {
        isRefreshing = true
        Task {
            await IPTVDataManager.shared.refreshContent(clearFirst: true)
            isRefreshing = false
        }
    }
}
