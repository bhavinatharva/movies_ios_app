//
//  ContentView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isSplashActive = true
    
    var body: some View {
        ZStack {
            if isSplashActive {
                SplashView {
                    withAnimation(.spring(response: 0.85, dampingFraction: 0.82)) {
                        isSplashActive = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
                .zIndex(1)
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(0)
            }
        }
        .onAppear {
            if let config = ApiConfig.shared {
                print("ApiConfig.shared.baseUrl", config.baseUrl ?? "Not available")
            }
        }
    }
}

#Preview {
    ContentView()
}
