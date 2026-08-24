//
//  AdaptiveCategoryView.swift

//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI

struct AdaptiveCategoryLayout<Content: View>: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    @ViewBuilder let content: () -> Content
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Geometry proxy can be used by the parent, but a simple heuristic for iPad Landscape is 
    // relying on a custom Environment property or just using horizontalSizeClass == .regular 
    // assuming most iPhones are compact horizontally. For true iPad landscape we can use size classes.
    @State private var isSidebarExpanded = true
    
    var body: some View {
        GeometryReader { geo in
            let isIPadLayout = horizontalSizeClass == .regular
            
            if isIPadLayout {
                // Sidebar Layout
                HStack(spacing: 0) {
                    if isSidebarExpanded {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Categories")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                
                                categoryButton(title: "All", isSelected: selectedCategory == nil) {
                                    withAnimation(.spring()) { selectedCategory = nil }
                                }
                                
                                ForEach(categories, id: \.self) { category in
                                    categoryButton(title: category, isSelected: selectedCategory == category) {
                                        withAnimation(.spring()) { selectedCategory = category }
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .frame(width: 260)
                        .background(Color.black.opacity(0.4))
                        .transition(.move(edge: .leading))
                    }
                    
                    // Main Content Area
                    ZStack(alignment: .topLeading) {
                        Color.appBackground.ignoresSafeArea()
                        content()
                        
                        // Sidebar Toggle Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSidebarExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isSidebarExpanded ? "sidebar.left" : "sidebar.right")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
            } else {
                // Top Sticky Chip Layout (iPhone & iPad Portrait)
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            chipButton(title: "All", isSelected: selectedCategory == nil) {
                                withAnimation(.spring()) { selectedCategory = nil }
                            }
                            
                            ForEach(categories, id: \.self) { category in
                                chipButton(title: category, isSelected: selectedCategory == category) {
                                    withAnimation(.spring()) { selectedCategory = category }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(
                        VisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
                            .ignoresSafeArea(edges: .top)
                    )
                    .zIndex(10)
                    
                    content()
                }
            }
        }
    }
    
    // MARK: - UI Subcomponents
    
    @ViewBuilder
    private func categoryButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PressScaleButtonStyle())
    }
    
    @ViewBuilder
    private func chipButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.white.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
