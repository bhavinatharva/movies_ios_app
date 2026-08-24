//
//  SettingsView.swift

//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var activePlaylist: Playlist?
    @State private var allowAdultContent: Bool = false
    

    
    @State private var userDataManager = UserDataManager.shared
    @State private var showHistoryAlert = false
    @State private var showFavoritesAlert = false
    

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        
                        
                        playlistSection
                        
                        if let playlist = activePlaylist, playlist.hasAdultContent {
                            adultContentSection(playlist: playlist)
                        }
                        
                        appearanceSection
                        
                        dataStorageSection
                        
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle(Constants.StringConstants.tabSettings)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                activePlaylist = PlaylistManager.shared.fetchDefaultPlaylist()
                allowAdultContent = activePlaylist?.userConsentedAdult ?? false
            }
        }
    }
    
    // MARK: - Sections
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .padding(.top, 8)
            
            VStack(spacing: 4) {
                Text(activePlaylist?.name ?? "No Active Playlist")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(hasDefaultPlaylist ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(hasDefaultPlaylist ? "Connected" : "Disconnected")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    

    
    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("ACCOUNT & SOURCE")
            
            SettingsCardContainer {
                NavigationLink(destination: PlaylistHubView()) {
                    SettingsRowUIComponent(
                        icon: "tv.inset.filled",
                        iconColor: .accentColor,
                        title: "Manage Playlists",
                        subtitle: "Add, remove, or switch active playlist",
                        trailing: Image(systemName: "chevron.right").foregroundColor(.gray)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if hasDefaultPlaylist {
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                    
                    Button(action: {
                        Task {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            await IPTVDataManager.shared.refreshContent()
                        }
                    }) {
                        SettingsRowUIComponent(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .blue,
                            title: "Refresh Content",
                            subtitle: "Fetch latest manually",
                            trailing: Image(systemName: "chevron.right").foregroundColor(.gray)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    

    
    private func adultContentSection(playlist: Playlist) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("CONTENT RESTRICTIONS")
            
            SettingsCardContainer {
                SettingsRowUIComponent(
                    icon: "exclamationmark.shield.fill",
                    iconColor: .red,
                    title: "Allow 18+ Content",
                    subtitle: "Enable access to 18+ contents",
                    trailing: Toggle("", isOn: Binding(
                        get: { self.allowAdultContent },
                        set: { newValue in
                            self.allowAdultContent = newValue
                            PlaylistManager.shared.updateAdultConsent(for: playlist.id, consented: newValue)
                            Task {
                                await IPTVDataManager.shared.refreshContent(clearFirst: true)
                            }
                        }
                    )).labelsHidden()
                )
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("APPEARANCE")
            
            SettingsCardContainer {
                SettingsRowUIComponent(
                    icon: "moon.fill",
                    iconColor: .indigo,
                    title: "Dark Mode",
                    subtitle: "Use dark theme for the app",
                    trailing: Toggle("", isOn: Binding(
                        get: { 
                            if userDataManager.currentTheme == .system {
                                return colorScheme == .dark
                            }
                            return userDataManager.currentTheme == .dark
                        },
                        set: { isDark in
                            userDataManager.currentTheme = isDark ? .dark : .light
                        }
                    )).labelsHidden()
                )
            }
        }
    }
    
    private var dataStorageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("DATA & STORAGE")
            
            SettingsCardContainer {
                Button(action: {
                    showHistoryAlert = true
                }) {
                    SettingsRowUIComponent(
                        icon: "clock.arrow.circlepath",
                        iconColor: .orange,
                        title: "Clear Watch History",
                        subtitle: "Permanently delete playback records",
                        trailing: EmptyView()
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .alert("Clear Watch History", isPresented: $showHistoryAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        UserDataManager.shared.recentlyWatched = []
                        // Clear history from CoreData persistent store
                        let context = IPTVLocalDatabase.shared.viewContext
                        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HistoryEntity")
                        if let results = try? context.fetch(fetchRequest) {
                            for obj in results {
                                context.delete(obj)
                            }
                            try? context.save()
                        }
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } message: {
                    Text("Are you sure you want to permanently delete your playback and history records?")
                }
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                
                Button(action: {
                    showFavoritesAlert = true
                }) {
                    SettingsRowUIComponent(
                        icon: "heart.slash.fill",
                        iconColor: .red,
                        title: "Clear Favorites",
                        subtitle: "Remove all saved items",
                        trailing: EmptyView()
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .alert("Clear Favorites", isPresented: $showFavoritesAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        UserDataManager.shared.favorites = []
                        // Clear favorites from CoreData persistent store
                        let context = IPTVLocalDatabase.shared.viewContext
                        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoritesEntity")
                        if let results = try? context.fetch(fetchRequest) {
                            for obj in results {
                                context.delete(obj)
                            }
                            try? context.save()
                        }
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                } message: {
                    Text("Are you sure you want to delete all saved items from your favorites list?")
                }
            }
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: 4) {
            Text("App Version 1.0 (Build 26)")
                .font(.caption)
                .foregroundColor(.gray)
            Text("© 2026 IPTV. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.bottom, 40)
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.gray)
            .padding(.leading, 16)
    }
}

// MARK: - UI Components

struct SettingsCardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct SettingsRowUIComponent<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let trailing: Trailing
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}
