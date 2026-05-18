//
//  MainTabView.swift
//  MoviesApp
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab(Constants.StringConstants.tabHome, systemImage: Constants.ImageConstants.tabHome) {
                HomeView()
            }
            Tab(Constants.StringConstants.tabLiveTV, systemImage: Constants.ImageConstants.tabLiveTV) {
                LiveTVView()
            }
            Tab(Constants.StringConstants.tabMovies, systemImage: Constants.ImageConstants.tabMovies) {
                VODMoviesView()
            }
            Tab(Constants.StringConstants.tabSeries, systemImage: Constants.ImageConstants.tabSeries) {
                SeriesView()
            }
            Tab(Constants.StringConstants.tabSettings, systemImage: Constants.ImageConstants.tabSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
