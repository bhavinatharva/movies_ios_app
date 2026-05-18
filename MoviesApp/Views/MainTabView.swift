//
//  MainTabView.swift
//  MoviesApp
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: IPTVTab = .home
    private var dataManager = IPTVDataManager.shared
    
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
        TabView(selection: $selectedTab) {
            ForEach(dataManager.availableTabs) { tab in
                tabViewContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: dataManager.availableTabs) { _, newTabs in
            if !newTabs.contains(selectedTab) {
                selectedTab = .home
            }
        }
    }
    
    @ViewBuilder
    private func tabViewContent(for tab: IPTVTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .liveTV:
            LiveTVView()
        case .movies:
            VODMoviesView()
        case .series:
            SeriesView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
}
