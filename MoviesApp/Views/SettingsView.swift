//
//  SettingsView.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var playlists: [Playlist] = []
    @State private var showingAddForm = false
    @State private var newName = ""
    @State private var newUrl = ""
    @Environment(\.dismiss) var dismiss
    
    private let manager = PlaylistManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if playlists.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tv.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No playlists added yet")
                                .foregroundColor(.gray)
                            
                            Button(action: { showingAddForm = true }) {
                                Text("Add Your First Playlist")
                                    .fontWeight(.bold)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 100)
                    } else {
                        List {
                            Section(header: Text("Your Playlists").foregroundColor(.gray)) {
                                ForEach(playlists) { playlist in
                                    PlaylistRow(playlist: playlist) {
                                        manager.setDefault(playlist)
                                        loadPlaylists()
                                    }
                                    .listRowBackground(Color.gray.opacity(0.1))
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            manager.deletePlaylist(playlist)
                                            loadPlaylists()
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
            }
            .navigationTitle("IPTV Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddForm = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                AddPlaylistView(name: $newName, url: $newUrl) {
                    manager.addPlaylist(name: newName, url: newUrl)
                    newName = ""
                    newUrl = ""
                    loadPlaylists()
                    showingAddForm = false
                }
            }
            .onAppear {
                loadPlaylists()
            }
        }
    }
    
    private func loadPlaylists() {
        playlists = manager.fetchAllPlaylists()
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(playlist.url)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if playlist.isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            } else {
                Button(action: onSetDefault) {
                    Text("Set Default")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddPlaylistView: View {
    @Binding var name: String
    @Binding var url: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Playlist Name (e.g. My Channels)", text: $name)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    TextField("Playlist URL (.m3u)", text: $url)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: onSave) {
                        Text("Add Playlist")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty || url.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || url.isEmpty)
                    
                    Spacer()
                }
                .padding()
                .padding(.top, 20)
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
