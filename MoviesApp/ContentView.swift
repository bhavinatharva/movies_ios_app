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
            Tab(Constants.StringConstants.tabUpcoming,systemImage:Constants.ImageConstants.tabUpcoming){
                UpcomingView()
            }
            Tab(Constants.StringConstants.tabSearch,systemImage: Constants.ImageConstants.tabSearch){
                SearchView()
            }
            Tab(Constants.StringConstants.tabDownloads,systemImage: Constants.ImageConstants.tabDownloads){
                Text(Constants.StringConstants.tabDownloads)
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
