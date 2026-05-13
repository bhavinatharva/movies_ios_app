//
//  ContentView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            Tab(Constants.StringConstants.tabHome,systemImage: Constants.ImageConstants.tabHome){
                HomeView()
            }
            Tab(Constants.StringConstants.tabActors,systemImage:Constants.ImageConstants.tabPerson){
                ActorsView()
            }
            Tab(Constants.StringConstants.tabUpcoming,systemImage:Constants.ImageConstants.tabUpcoming){
                UpcomingView()
            }
            Tab(Constants.StringConstants.tabSearch,systemImage: Constants.ImageConstants.tabSearch){
                SearchView()
            }
            Tab(Constants.StringConstants.tabRecent, systemImage: Constants.ImageConstants.tabRecent) {
                RecentMoviesView()
            }
            Tab(Constants.StringConstants.tabDownloads,systemImage: Constants.ImageConstants.tabDownloads){
                DownloadView()
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
