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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    if !hasDefaultPlaylist {
                        Section(header: Text("Add IPTV M3U Playlist").foregroundColor(.gray)) {
                            TextField("Playlist Name", text: $playlistName)
                                .foregroundColor(.white)
                                .listRowBackground(Color.gray.opacity(0.1))
                            
                            TextField("M3U Playlist URL", text: $playlistUrl)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundColor(.white)
                                .listRowBackground(Color.gray.opacity(0.1))
                        }
                        
                        Section {
                            Button(action: {
                                Task {
                                    await loadPlaylist()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Load Playlist")
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
                    } else {
                        Section(header: Text("Loaded Playlist").foregroundColor(.gray)) {
                            if let defaultPlaylist = playlistManager.fetchDefaultPlaylist() {
                                HStack {
                                    Text("Name")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(defaultPlaylist.name)
                                        .foregroundColor(.gray)
                                }
                                .listRowBackground(Color.gray.opacity(0.1))
                                
                                HStack {
                                    Text("URL")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(defaultPlaylist.url)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                                .listRowBackground(Color.gray.opacity(0.1))
                            }
                        }
                        
                        Section {
                            Button(action: {
                                if let defaultPlaylist = playlistManager.fetchDefaultPlaylist() {
                                    playlistManager.deletePlaylist(defaultPlaylist)
                                }
                                hasDefaultPlaylist = false
                                playlistUrl = ""
                            }) {
                                Text("Unload Playlist")
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .listRowBackground(Color.gray.opacity(0.1))
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
        }
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
        } catch {
            errorMessage = "Failed to load IPTV source: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    SettingsView()
}
