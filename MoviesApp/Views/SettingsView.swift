//
//  SettingsView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("show_adult_content") private var showAdultContent = false
    @State private var userDataManager = UserDataManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                List {
                    Section {
                        NavigationLink(destination: PlaylistsListView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "tv.inset.filled")
                                    .foregroundColor(.accentColor)
                                    .font(.title3)
                                
                                Text("Your Playlists")
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                             }
                        }
                        .listRowBackground(Color.appCardBackground)
                    }
                    
                    Section(header: Text("Content Filter").foregroundColor(.secondary)) {
                        Toggle(isOn: $showAdultContent) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Show Adult Content (18+)")
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    Text("Toggle to blur adult content")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .listRowBackground(Color.appCardBackground)
                    }
                    
                    Section(header: Text("Appearance").foregroundColor(.secondary)) {
                        Picker("Theme", selection: $userDataManager.currentTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.appCardBackground)
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
}

#Preview {
    SettingsView()
}
