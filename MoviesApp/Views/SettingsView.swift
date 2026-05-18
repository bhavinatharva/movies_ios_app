//
//  SettingsView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
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
                    
                    Section(header: Text("Appearance").foregroundColor(.secondary)) {
                        Picker("Theme", selection: $userDataManager.currentTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .tint(.accentColor)
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
