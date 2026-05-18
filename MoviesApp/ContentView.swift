//
//  ContentView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }.onAppear{
            if let config = ApiConfig.shared {
                print("ApiConfig.shared.baseUrl", config.baseUrl ?? "Not available")
            }
        }
    }
}

#Preview {
    ContentView()
}
