//
//  MainTabView.swift

//

import SwiftUI
import AVFoundation

struct MainTabView: View {
    @State private var selectedTab: IPTVTab = .home
    @Bindable private var dataManager = IPTVDataManager.shared
    @EnvironmentObject var globalPlayerManager: GlobalPlayerManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init() {
        #if os(iOS)
        // Configure native iOS TabBar appearance for a premium glass translucent effect
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Apply translucency & blur configurations
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.15)

        // Active (Selected) styling
        let safeAccentColor = UIColor(named: "AccentColor") ?? UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.iconColor = safeAccentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: safeAccentColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        // Inactive (Unselected) styling
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }

    #if os(tvOS)
    @State private var tvSelectedTab: Int = 0
    #endif

    var body: some View {
        ZStack {
            #if os(tvOS)
            TabView(selection: $tvSelectedTab) {
                HomeView()
                    .tabItem { Label(IPTVTab.home.title, systemImage: IPTVTab.home.systemImage) }
                    .tag(0)

                if dataManager.availableTabs.contains(.liveTV) {
                    LiveTVView()
                        .tabItem { Label(IPTVTab.liveTV.title, systemImage: IPTVTab.liveTV.systemImage) }
                        .tag(1)
                }

                if dataManager.availableTabs.contains(.movies) {
                    VODMoviesView()
                        .tabItem { Label(IPTVTab.movies.title, systemImage: IPTVTab.movies.systemImage) }
                        .tag(2)
                }

                if dataManager.availableTabs.contains(.series) {
                    SeriesView()
                        .tabItem { Label(IPTVTab.series.title, systemImage: IPTVTab.series.systemImage) }
                        .tag(3)
                }

                RecentView()
                    .tabItem { Label(IPTVTab.recent.title, systemImage: IPTVTab.recent.systemImage) }
                    .tag(4)

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(5)

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(6)
            }
            #else
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    SidebarView(selectedTab: $selectedTab)
                    tabViewContent(for: selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem { Label(IPTVTab.home.title, systemImage: IPTVTab.home.systemImage) }
                        .tag(IPTVTab.home)

                    RecentView()
                        .tabItem { Label(IPTVTab.recent.title, systemImage: IPTVTab.recent.systemImage) }
                        .tag(IPTVTab.recent)

                    if dataManager.availableTabs.contains(.liveTV) {
                        LiveTVView()
                            .tabItem { Label(IPTVTab.liveTV.title, systemImage: IPTVTab.liveTV.systemImage) }
                            .tag(IPTVTab.liveTV)
                    }

                    if dataManager.availableTabs.contains(.movies) {
                        VODMoviesView()
                            .tabItem { Label(IPTVTab.movies.title, systemImage: IPTVTab.movies.systemImage) }
                            .tag(IPTVTab.movies)
                    }

                    if dataManager.availableTabs.contains(.series) {
                        SeriesView()
                            .tabItem { Label(IPTVTab.series.title, systemImage: IPTVTab.series.systemImage) }
                            .tag(IPTVTab.series)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            #endif
        }
        .fullScreenCover(isPresented: Binding(
            get: { globalPlayerManager.currentTitle != nil },
            set: { _ in } // Dismissal is handled by StreamingPlayerView calling stop()
        )) {
            if let title = globalPlayerManager.currentTitle,
               let urlStr = globalPlayerManager.player.currentItem?.asset as? AVURLAsset {
                StreamingPlayerView(
                    url: urlStr.url,
                    title: title,
                    streamId: globalPlayerManager.streamId,
                    subtitle: globalPlayerManager.subtitle,
                    isLive: globalPlayerManager.isLive,
                    logoUrl: globalPlayerManager.currentArtwork,
                    nextEpisodeTitle: globalPlayerManager.nextEpisodeTitle,
                    onPlayNext: globalPlayerManager.onPlayNext
                )
            }
        }
    }

    @ViewBuilder
    private func tabViewContent(for tab: IPTVTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .recent:
            RecentView()
        case .liveTV:
            LiveTVView()
        case .movies:
            VODMoviesView()
        case .series:
            SeriesView()
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: IPTVTab
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @State private var activePlaylist: Playlist?
    @State private var showSettings = false
    @State private var showSearch = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Branding & Status Header
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(colors: [Color.accentColor, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("IPTV PRO")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(hasDefaultPlaylist ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                            Text(hasDefaultPlaylist ? (activePlaylist?.name ?? "Connected") : "No Playlist")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 28)
            .padding(.horizontal, 20)
            
            // Primary Navigation Items
            VStack(spacing: 6) {
                ForEach(IPTVTab.allCases) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 17, weight: selectedTab == tab ? .bold : .medium))
                                .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                                .frame(width: 24)
                            
                            Text(tab.title)
                                .font(.system(size: 15, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .white : Color.white.opacity(0.7))
                            
                            Spacer()
                            
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .frame(width: 4, height: 18)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedTab == tab ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
            
            // Quick Action Utilities (Search & Settings)
            VStack(spacing: 8) {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                Button(action: { showSearch = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                        Text("Search")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showSettings = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                        Text("Settings")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 24)
        }
        .frame(width: 260)
        .background(Color(red: 0.06, green: 0.06, blue: 0.08))
        .overlay(
            Rectangle()
                .frame(width: 0.5)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .trailing
        )
        .ignoresSafeArea(.all, edges: .vertical)
        .onAppear {
            activePlaylist = PlaylistManager.shared.fetchDefaultPlaylist()
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
}
