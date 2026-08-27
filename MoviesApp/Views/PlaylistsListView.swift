//
//  PlaylistsListView.swift

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
                                                await IPTVDataManager.shared.refreshContent(clearFirst: true)
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
        
        let validationResult = IPTVURLValidator.validateIPTVSource(input: urlString)
        
        guard validationResult.isValid,
              let sanitizedStr = validationResult.sanitizedUrl else {
            errorMessage = validationResult.errorMessage ?? "Invalid IPTV source. Please enter a valid M3U, Xtream API, or HLS URL."
            isLoading = false
            return
        }
        
        // Verify the URL is reachable and not returning a 404
        guard let url = URL(string: sanitizedStr) else {
            errorMessage = "Invalid URL format."
            isLoading = false
            return
        }
        
        do {
            var getRequest = URLRequest(url: url)
            getRequest.httpMethod = "GET"
            getRequest.setValue("bytes=0-200", forHTTPHeaderField: "Range") // Fetch a small snippet
            getRequest.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: getRequest)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    errorMessage = "Playlist link is invalid or expired (404 Not Found)."
                    isLoading = false
                    return
                } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    errorMessage = "Access denied (Invalid username/password or IP blocked)."
                    isLoading = false
                    return
                }
                
                // Some servers return 200 OK but give a fake HTML 404 page
                if let content = String(data: data, encoding: .utf8)?.lowercased() {
                    if content.contains("404 not found") || content.contains("<html") {
                        errorMessage = "Playlist link is invalid (Server returned an HTML error page)."
                        isLoading = false
                        return
                    }
                }
            }
        } catch {
            errorMessage = "Failed to connect to the provider's server."
            isLoading = false
            return
        }
        
        let finalName = name.isEmpty ? "My M3U Playlist" : name
        playlistManager.addPlaylist(name: finalName, url: sanitizedStr)
        
        await IPTVDataManager.shared.refreshContent()
        onSuccess()
        dismiss()
        
        isLoading = false
    }
}

#Preview {
    PlaylistsListView()
}
