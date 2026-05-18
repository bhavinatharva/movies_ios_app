//
//  ContentView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
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
