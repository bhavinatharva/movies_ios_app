//
//  UpcomingView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct UpcomingView: View {
    
    var upcomingModel = UpcomingViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                switch upcomingModel.upcomingStatus {
                case ApiFetchStatus.notstarted, .loading:
                    ProgressView()
                case ApiFetchStatus.success:
                    VerticalListView(titles:upcomingModel.upcomingMovies,canDelete: false)
                        .navigationDestination(for: TrendingModel.self) { title in
                            MovieDetailView(title: title)
                        }
        
                case ApiFetchStatus.error(underlyingError: let error):
                    ContentUnavailableView("Connection Error", systemImage: "wifi.exclamationmark", description: Text(error.localizedDescription))
                }
            }
            .navigationTitle(Constants.StringConstants.tabUpcoming)
            .task {
                await upcomingModel.getUpcomingsMovies()
            }
        }
    }
}

#Preview {
    UpcomingView()
}
