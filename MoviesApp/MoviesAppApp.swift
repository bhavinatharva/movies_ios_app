//
//  MoviesAppApp.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI
import SwiftData

@main
struct MoviesAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for :TrendingModel.self)
    }
}
