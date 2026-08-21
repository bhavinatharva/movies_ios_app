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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
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
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    SidebarView(selectedTab: $selectedTab)
                    tabViewContent(for: selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
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
            }
            
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

struct SidebarView: View {
    @Binding var selectedTab: IPTVTab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MoviesApp")
                .font(.title2)
                .fontWeight(.black)
                .foregroundColor(.accentColor)
                .padding(.top, 60)
                .padding(.bottom, 20)
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                ForEach(IPTVTab.allCases) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: tab.systemImage)
                                .font(.title3)
                                .frame(width: 24)
                            Text(tab.title)
                                .font(.headline)
                            Spacer()
                        }
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(selectedTab == tab ? Color.accentColor : Color.clear)
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Spacer()
        }
        .frame(width: 250)
        .background(Color.black.opacity(0.4))
        .background(VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark)))
        .ignoresSafeArea()
    }
}

#Preview {
    MainTabView()
}
