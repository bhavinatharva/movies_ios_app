//
//  PlaylistsListView.swift
//  MoviesApp
//
//  Created by Antigravity on 18/05/26.
//

import SwiftUI

struct PlaylistsListView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    private let playlistManager = PlaylistManager.shared
    
    @State private var playlists: [Playlist] = []
    @State private var isShowingAddSheet = false
    @State private var isActivating = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if playlists.isEmpty {
                    ContentUnavailableView(
                        "No Playlists Loaded",
                        systemImage: "tv.slash",
                        description: Text("Tap the plus button below to add your first IPTV playlist.")
                    )
                } else {
                    List {
                        Section(header: Text("Your IPTV Playlists").foregroundColor(.secondary)) {
                            ForEach(playlists) { playlist in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(playlist.name)
                                                .foregroundColor(.primary)
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
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    if !playlist.isDefault {
                                        Button(action: {
                                            isActivating = true
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            playlistManager.setDefault(playlist)
                                            refreshPlaylists()
                                            Task {
                                                await IPTVDataManager.shared.refreshContent()
                                                isActivating = false
                                            }
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
                                        .disabled(isActivating)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.title3)
                                    }
                                }
                                .listRowBackground(Color.appCardBackground)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        playlistManager.deletePlaylist(playlist)
                                        refreshPlaylists()
                                        Task {
                                            await IPTVDataManager.shared.refreshContent()
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
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
                        isShowingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.accentColor)
                                    .shadow(color: Color.accentColor.opacity(0.45), radius: 10, x: 0, y: 5)
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("IPTV Playlists")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshPlaylists()
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddPlaylistSheet {
                refreshPlaylists()
            }
        }
    }
    
    private func refreshPlaylists() {
        playlists = playlistManager.fetchAllPlaylists()
        hasDefaultPlaylist = !playlists.isEmpty
    }
}

struct AddPlaylistSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSuccess: () -> Void
    
    @State private var name = "My M3U Playlist"
    @State private var urlString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let playlistManager = PlaylistManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Playlist Details").foregroundColor(.secondary)) {
                        TextField("Playlist Name", text: $name)
                            .listRowBackground(Color.appCardBackground)
                        
                        TextField("M3U Playlist URL", text: $urlString)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .listRowBackground(Color.appCardBackground)
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .listRowBackground(Color.clear)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            Task {
                                await loadPlaylist()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text("Load & Save Playlist")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .foregroundColor(.accentColor)
                        .disabled(isLoading || urlString.isEmpty)
                        .listRowBackground(Color.appCardBackground)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add IPTV Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func loadPlaylist() async {
        isLoading = true
        errorMessage = nil
        
        let validationResult = IPTVValidator.validateIPTVSource(input: urlString)
        
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
                    name: name.isEmpty ? "Direct HLS Stream" : name,
                    streamUrl: url,
                    logoUrl: nil,
                    category: "Direct HLS Stream",
                    epgId: nil
                )
                channels = [channel]
            case .directDASH:
                let channel = IPTVChannel(
                    name: name.isEmpty ? "Direct DASH Stream" : name,
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
            
            let finalName = name.isEmpty ? "My M3U Playlist" : name
            playlistManager.addPlaylist(name: finalName, url: sanitizedStr)
            playlistManager.cacheChannels(channels, forUrl: sanitizedStr)
            
            await IPTVDataManager.shared.refreshContent()
            onSuccess()
            dismiss()
        } catch {
            errorMessage = "Failed to load IPTV source: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    PlaylistsListView()
}
