//
//  SettingsView.swift

//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    
    @State private var activePlaylist: Playlist?
    @State private var allowAdultContent: Bool = false
    
    // Playback and Custom Settings preferences (persisted persistently)
    @AppStorage("resume_playback") private var resumePlayback = true
    @AppStorage("auto_play_next") private var autoPlayNext = true
    @AppStorage("auto_play_trailers") private var autoPlayTrailers = true
    @AppStorage("start_on_live") private var startOnLive = false
    @AppStorage("epg_display") private var epgDisplay = true
    @AppStorage("default_audio_lang") private var defaultAudioLang = "English"
    @AppStorage("default_sub_lang") private var defaultSubLang = "Off"
    
    @State private var userDataManager = UserDataManager.shared
    @State private var showHistoryAlert = false
    @State private var showFavoritesAlert = false
    
    private let audioLanguages = ["English", "Spanish", "French", "German", "Japanese"]
    private let subtitleLanguages = ["Off", "English", "Spanish", "French", "German"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        
                        premiumBannerSection
                        
                        playlistSection
                        
                        playerSettingsSection
                        
                        liveTVSettingsSection
                        
                        audioSubtitlesSection
                        
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
    
    @State private var showPremiumPaywall = false
    
    private var premiumBannerSection: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showPremiumPaywall = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to PRO")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Unlock unlimited features & ad-free streaming.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(
                LinearGradient(colors: [Color.accentColor, Color.purple], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
            .shadow(color: Color.accentColor.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(PressScaleButtonStyle())
        .fullScreenCover(isPresented: $showPremiumPaywall) {
            PremiumPaywallView()
        }
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
                        subtitle: "Add, remove, or switch active IPTV sources",
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
                            subtitle: "Fetch latest channels and VODs manually",
                            trailing: Image(systemName: "chevron.right").foregroundColor(.gray)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var playerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("PLAYER SETTINGS")
            
            SettingsCardContainer {
                SettingsRowUIComponent(
                    icon: "arrow.uturn.backward.circle.fill",
                    iconColor: .blue,
                    title: "Resume Playback",
                    subtitle: "Automatically resume where you left off",
                    trailing: Toggle("", isOn: $resumePlayback).labelsHidden()
                )
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                
                SettingsRowUIComponent(
                    icon: "forward.end.fill",
                    iconColor: .purple,
                    title: "Auto-Play Next Episode",
                    subtitle: "Start next episode automatically",
                    trailing: Toggle("", isOn: $autoPlayNext).labelsHidden()
                )
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                
                SettingsRowUIComponent(
                    icon: "film.fill",
                    iconColor: .indigo,
                    title: "Auto-Play Trailers",
                    subtitle: "Play movie trailers on detail pages",
                    trailing: Toggle("", isOn: $autoPlayTrailers).labelsHidden()
                )
            }
        }
    }
    
    private var liveTVSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("LIVE TV SETTINGS")
            
            SettingsCardContainer {
                SettingsRowUIComponent(
                    icon: "tv.fill",
                    iconColor: .pink,
                    title: "Start on Live TV",
                    subtitle: "Launch Live TV tab automatically on startup",
                    trailing: Toggle("", isOn: $startOnLive).labelsHidden()
                )
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                
                SettingsRowUIComponent(
                    icon: "calendar.badge.clock",
                    iconColor: .cyan,
                    title: "Show EPG Information",
                    subtitle: "Display program timelines for channels",
                    trailing: Toggle("", isOn: $epgDisplay).labelsHidden()
                )
            }
        }
    }
    
    private var audioSubtitlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("AUDIO & SUBTITLES")
            
            SettingsCardContainer {
                SettingsRowUIComponent(
                    icon: "speaker.wave.2.bubble.left.fill",
                    iconColor: .teal,
                    title: "Default Audio",
                    subtitle: "Preferred language for audio tracks",
                    trailing: Picker("", selection: $defaultAudioLang) {
                        ForEach(audioLanguages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    .tint(.gray)
                    .labelsHidden()
                )
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 48)
                
                SettingsRowUIComponent(
                    icon: "captions.bubble.fill",
                    iconColor: .green,
                    title: "Default Subtitle",
                    subtitle: "Preferred language for closed captions",
                    trailing: Picker("", selection: $defaultSubLang) {
                        ForEach(subtitleLanguages, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                    .tint(.gray)
                    .labelsHidden()
                )
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
                    title: "Allow Adult Content (18+)",
                    subtitle: "Enable access to 18+ categories for this playlist",
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
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                        
                        Text("App Theme")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    
                    Picker("Theme", selection: $userDataManager.currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
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
