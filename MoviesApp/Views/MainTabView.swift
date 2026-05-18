//
//  MainTabView.swift
//  MoviesApp
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: IPTVTab = .home
    private var dataManager = IPTVDataManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70) // Prevents tab bar from overlapping scroll content
            }
            
            // Custom Glassmorphic Capsule Tab Bar
            HStack(spacing: 20) {
                ForEach(dataManager.availableTabs) { tab in
                    tabButton(tab: tab)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassBackground(cornerRadius: 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: dataManager.availableTabs) { _, newTabs in
            if !newTabs.contains(selectedTab) {
                selectedTab = .home
            }
        }
    }
    
    private func tabButton(tab: IPTVTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
                selectedTab = tab
            }
            // Trigger light visual/haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.title3)
                    .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                    .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0), value: selectedTab)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                    .foregroundColor(selectedTab == tab ? .white : .gray)
            }
            .frame(width: 50)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
