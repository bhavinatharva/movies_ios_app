//
//  MainTabView.swift
//  MoviesApp
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    LiveTVView()
                case 2:
                    SettingsView()
                default:
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70) // Prevents tab bar from overlapping scroll content
            }
            
            // Custom Glassmorphic Capsule Tab Bar
            HStack(spacing: 36) {
                tabButton(index: 0, title: "Home", systemImage: "house.fill")
                tabButton(index: 1, title: "Live TV", systemImage: "tv.fill")
                tabButton(index: 2, title: "Settings", systemImage: "gearshape.fill")
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .glassBackground(cornerRadius: 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private func tabButton(index: Int, title: String, systemImage: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
                selectedTab = index
            }
            // Trigger light visual/haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(selectedTab == index ? .accentColor : .gray)
                    .scaleEffect(selectedTab == index ? 1.15 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0), value: selectedTab)
                
                Text(title)
                    .font(.system(size: 10, weight: selectedTab == index ? .bold : .medium))
                    .foregroundColor(selectedTab == index ? .white : .gray)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
