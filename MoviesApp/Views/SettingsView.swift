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
        
        var sanitizedUrl = playlistUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitizedUrl = sanitizedUrl.replacingOccurrences(of: "\r", with: "")
        sanitizedUrl = sanitizedUrl.replacingOccurrences(of: "\n", with: "")
        
        if !sanitizedUrl.lowercased().hasPrefix("http://") && !sanitizedUrl.lowercased().hasPrefix("https://") {
            sanitizedUrl = "http://" + sanitizedUrl
        }
        
        guard let url = URL(string: sanitizedUrl) else {
            errorMessage = "Invalid URL format."
            isLoading = false
            return
        }
        
        do {
            let channels = try await IPTVService.shared.fetchM3U(url: url)
            guard !channels.isEmpty else {
                errorMessage = "The playlist is empty or invalid."
                isLoading = false
                return
            }
            
            let name = playlistName.isEmpty ? "My M3U Playlist" : playlistName
            playlistManager.addPlaylist(name: name, url: sanitizedUrl)
            playlistManager.cacheChannels(channels, forUrl: sanitizedUrl)
            
            hasDefaultPlaylist = true
            playlistUrl = ""
        } catch {
            errorMessage = "Failed to load M3U: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    SettingsView()
}
