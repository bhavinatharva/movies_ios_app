//
//  SettingsView.swift
//  MoviesApp
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    private let playlistManager = PlaylistManager.shared
    
    @State private var playlistName = "My M3U Playlist"
    @State private var playlistUrl = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var playlists: [Playlist] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    // 1. Playlists List Section
                    if !playlists.isEmpty {
                        Section(header: Text("Your IPTV Playlists").foregroundColor(.gray)) {
                            ForEach(playlists) { playlist in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(playlist.name)
                                                .foregroundColor(.white)
                                                .fontWeight(playlist.isDefault ? .bold : .regular)
                                            
                                            if playlist.isDefault {
                                                Text("Active")
                                                    .font(.caption2)
                                                    .fontWeight(.black)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.accentColor.opacity(0.2))
                                                    .foregroundColor(.accentColor)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        Text(playlist.url)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    if !playlist.isDefault {
                                        Button(action: {
                                            playlistManager.setDefault(playlist)
                                            refreshPlaylists()
                                        }) {
                                            Text("Activate")
                                                .font(.footnote)
                                                .fontWeight(.bold)
                                                .foregroundColor(.accentColor)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.title3)
                                    }
                                }
                                .listRowBackground(Color.gray.opacity(0.1))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        playlistManager.deletePlaylist(playlist)
                                        refreshPlaylists()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            ContentUnavailableView(
                                "No Playlists Loaded",
                                systemImage: "tv.slash",
                                description: Text("Add your M3U link or Xtream URL below to get started.")
                            )
                            .foregroundColor(.white)
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    // 2. Add Playlist Section
                    Section(header: Text("Add New IPTV Source").foregroundColor(.gray)) {
                        TextField("Playlist Name", text: $playlistName)
                            .foregroundColor(.white)
                            .listRowBackground(Color.gray.opacity(0.1))
                        
                        TextField("M3U Playlist URL", text: $playlistUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.white)
                            .listRowBackground(Color.gray.opacity(0.1))
                        
                        Button(action: {
                            Task {
                                await loadPlaylist()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Load & Save Playlist")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .foregroundColor(.accentColor)
                        .disabled(isLoading || playlistUrl.isEmpty)
                        .listRowBackground(Color.gray.opacity(0.1))
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .listRowBackground(Color.clear)
                        }
                    }
                    
                    Section(footer: Text("App Version 1.0").frame(maxWidth: .infinity, alignment: .center)) {
                        EmptyView()
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Constants.StringConstants.tabSettings)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshPlaylists()
            }
        }
    }
    
    private func refreshPlaylists() {
        playlists = playlistManager.fetchAllPlaylists()
        hasDefaultPlaylist = !playlists.isEmpty
    }
    
    private func loadPlaylist() async {
        isLoading = true
        errorMessage = nil
        
        let validationResult = IPTVValidator.validateIPTVSource(input: playlistUrl)
        
        guard validationResult.isValid,
              let sanitizedStr = validationResult.sanitizedUrl,
              let url = URL(string: sanitizedStr) else {
            errorMessage = validationResult.errorMessage ?? "Invalid IPTV source. Please enter a valid M3U, Xtream API, or HLS URL."
            isLoading = false
            return
        }
        
        do {
            let channels: [IPTVChannel]
            
            switch validationResult.type {
            case .m3uPlaylist:
                channels = try await IPTVService.shared.fetchM3U(url: url)
            case .xtreamCodes:
                if url.path.contains("player_api.php") {
                    let queryParams = url.queryParameters
                    let username = queryParams["username"] ?? ""
                    let password = queryParams["password"] ?? ""
                    let serverUrl = "\(url.scheme ?? "http")://\(url.host ?? "")\(url.port != nil ? ":\(url.port!)" : "")"
                    let creds = XtreamCredentials(serverUrl: serverUrl, username: username, password: password)
                    channels = try await IPTVService.shared.fetchXtreamChannels(creds: creds)
                } else {
                    channels = try await IPTVService.shared.fetchM3U(url: url)
                }
            case .directHLS:
                let channel = IPTVChannel(
                    name: playlistName.isEmpty ? "Direct HLS Stream" : playlistName,
                    streamUrl: url,
                    logoUrl: nil,
                    category: "Direct HLS Stream",
                    epgId: nil
                )
                channels = [channel]
            case .directDASH:
                let channel = IPTVChannel(
                    name: playlistName.isEmpty ? "Direct DASH Stream" : playlistName,
                    streamUrl: url,
                    logoUrl: nil,
                    category: "Direct DASH Stream",
                    epgId: nil
                )
                channels = [channel]
            case .unknown:
                errorMessage = "Invalid IPTV source. Please enter a valid M3U, Xtream API, or HLS URL."
                isLoading = false
                return
            }
            
            guard !channels.isEmpty else {
                errorMessage = "The playlist is empty or invalid."
                isLoading = false
                return
            }
            
            let name = playlistName.isEmpty ? "My M3U Playlist" : playlistName
            playlistManager.addPlaylist(name: name, url: sanitizedStr)
            playlistManager.cacheChannels(channels, forUrl: sanitizedStr)
            
            hasDefaultPlaylist = true
            playlistUrl = ""
            refreshPlaylists()
        } catch {
            errorMessage = "Failed to load IPTV source: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    SettingsView()
}
