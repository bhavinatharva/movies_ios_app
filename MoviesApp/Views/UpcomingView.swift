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
            GeometryReader { geo in
                switch upcomingModel.upcomingStatus {
                case ApiFetchStatus.notstarted:
                    EmptyView()
                case ApiFetchStatus.loading:
                    ProgressView()
                        .frame(width: geo.size.width,height: geo.size.height)
                case ApiFetchStatus.success:
                    VerticalListView(titles:upcomingModel.upcomingMovies)
                    .navigationDestination(for: TrendingModel.self) { title in
                        MovieDetailView(title: title)
                    }
        
                case ApiFetchStatus.error(underlyingError: let error):
                    Text("Error from API : \(error.localizedDescription)")
                }
            }.task {
                await upcomingModel.getUpcomingsMovies()
            }
        }
    }
}

#Preview {
    UpcomingView()
}
