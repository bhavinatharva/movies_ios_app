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
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<10, id: \.self) { _ in
                                HStack(spacing: 16) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 100, height: 140)
                                    VStack(alignment: .leading, spacing: 12) {
                                        Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 20)
                                        Rectangle().fill(Color.gray.opacity(0.15)).frame(width: 150, height: 16)
                                    }
                                }
                                .padding(.horizontal)
                                .shimmer()
                            }
                        }
                        .padding(.vertical)
                    }
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
