//
//  MainTabView.swift
//  MoviesApp
//

import SwiftUI
import AVFoundation

struct MainTabView: View {
    @State private var selectedTab: IPTVTab = .home
    @Bindable private var dataManager = IPTVDataManager.shared
    @EnvironmentObject var globalPlayerManager: GlobalPlayerManager
    
    init() {
        // Configure native iOS TabBar appearance for a premium glass translucent effect
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Apply translucency & blur configurations
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        
        // Active (Selected) styling
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.accentColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.accentColor),
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
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ForEach(IPTVTab.allCases) { tab in
                    tabViewContent(for: tab)
                        .tabItem {
                            Label(tab.title, systemImage: tab.systemImage)
                        }
                        .tag(tab)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // Global Persistent Mini Player Overlay
            MiniPlayerView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { !globalPlayerManager.isMinimized && globalPlayerManager.currentTitle != nil },
            set: { _ in } // Dismissal is handled by StreamingPlayerView calling minimize()
        )) {
            if let title = globalPlayerManager.currentTitle,
               let urlStr = globalPlayerManager.player.currentItem?.asset as? AVURLAsset {
                StreamingPlayerView(url: urlStr.url, title: title)
            }
        }
        .sheet(isPresented: $dataManager.showAdultConsentPrompt) {
            AdultConsentModal(dataManager: dataManager)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
                .presentationBackground(.thinMaterial)
                .interactiveDismissDisabled()
        }
    }
    @ViewBuilder
    private func tabViewContent(for tab: IPTVTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .liveTV:
            LiveTVView()
        case .vod:
            VODView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
}
