//
//  SettingsView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("show_adult_content") private var showAdultContent = false
    
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
            Form {
                // Section 1: PLAYLISTS & ACCOUNT
                Section(header: Text("Account & Source")) {
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
                    
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("IPTV Connection Status")
                                .fontWeight(.medium)
                            Text(hasDefaultPlaylist ? "Connected" : "No active playlist")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if hasDefaultPlaylist {
                        Button(action: {
                            Task {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                await IPTVDataManager.shared.refreshContent()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Refresh Playlist Content")
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    Text("Fetch again for new channels and VODs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Section 2: APPEARANCE & FILTER
                Section(header: Text("Appearance & Filters")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(.orange)
                            Text("App Theme")
                                .fontWeight(.medium)
                        }
                        
                        Picker("Theme", selection: $userDataManager.currentTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle(isOn: $showAdultContent) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.red)
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
                }
                
                // Section 3: PLAYBACK PREFERENCES
                Section(header: Text("Playback Settings")) {
                    Toggle(isOn: $resumePlayback) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Resume Playback")
                                    .fontWeight(.medium)
                                Text("Automatically resume where you left off")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $autoPlayNext) {
                        HStack(spacing: 12) {
                            Image(systemName: "forward.end.fill")
                                .foregroundColor(.purple)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Play Next Episode")
                                    .fontWeight(.medium)
                                Text("Start next episode automatically")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $autoPlayTrailers) {
                        HStack(spacing: 12) {
                            Image(systemName: "film.fill")
                                .foregroundColor(.indigo)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Play Trailers")
                                    .fontWeight(.medium)
                                Text("Play movie trailers on detail pages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Section 4: LIVE TV SETTINGS
                Section(header: Text("Live TV Settings")) {
                    Toggle(isOn: $startOnLive) {
                        HStack(spacing: 12) {
                            Image(systemName: "tv.fill")
                                .foregroundColor(.pink)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start on Live TV")
                                    .fontWeight(.medium)
                                Text("Launch Live TV tab automatically on startup")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $epgDisplay) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.cyan)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show EPG Information")
                                    .fontWeight(.medium)
                                Text("Display program timelines for channels")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Section 5: AUDIO & SUBTITLES
                Section(header: Text("Audio & Subtitles")) {
                    Picker(selection: $defaultAudioLang, label: HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2.bubble.left.fill")
                            .foregroundColor(.teal)
                        Text("Default Audio")
                            .fontWeight(.medium)
                    }) {
                        ForEach(audioLanguages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker(selection: $defaultSubLang, label: HStack(spacing: 12) {
                        Image(systemName: "captions.bubble.fill")
                            .foregroundColor(.green)
                        Text("Default Subtitle")
                            .fontWeight(.medium)
                    }) {
                        ForEach(subtitleLanguages, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Section 6: DATA & STORAGE
                Section(header: Text("Data & Storage")) {
                    Button(action: {
                        showHistoryAlert = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("Clear Watch History")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
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
                    
                    Button(action: {
                        showFavoritesAlert = true
                    }) {
                        HStack {
                            Image(systemName: "heart.slash.fill")
                                .foregroundColor(.red)
                            Text("Clear Favorites")
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                    }
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
                
                // Section 7: ABOUT
                Section(footer: VStack(alignment: .center, spacing: 4) {
                    Text("App Version 1.0 (Build 26)")
                    Text("© 2026 MoviesApp. All rights reserved.")
                }.frame(maxWidth: .infinity, alignment: .center)) {
                    EmptyView()
                }
            }
            .navigationTitle(Constants.StringConstants.tabSettings)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
