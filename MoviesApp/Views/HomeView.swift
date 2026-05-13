//
//  HomeView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    var homeViewModel = HomeViewModel()
    @State private var detailNavigationPath = NavigationPath()
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch homeViewModel.homeStatus {
                case .notstarted, .loading:
                    ProgressView()
                        .tint(.white)
                case .success:
                    ScrollView {
                        VStack(spacing: 24) {
                            MovieHeroHeaderView(
                                movie: homeViewModel.heroTitle,
                                onPlay: {
                                    detailNavigationPath.append(homeViewModel.heroTitle)
                                },
                                onAddToList: {
                                    modelContext.insert(homeViewModel.heroTitle)
                                    try? modelContext.save()
                                }
                            )
                            
                            MovieHorizontalListView(
                                header: Constants.StringConstants.nowPlayingMovies,
                                movies: homeViewModel.nowPlayingMovies,
                                onSelect: { title in detailNavigationPath.append(title) }
                            )
                            
                            MovieHorizontalListView(
                                header: Constants.StringConstants.popularMovies,
                                movies: homeViewModel.popularMovies,
                                onSelect: { title in detailNavigationPath.append(title) }
                            )
                            
                            MovieHorizontalListView(
                                header: Constants.StringConstants.trendingMovies,
                                movies: homeViewModel.trendingMovies,
                                onSelect: { title in detailNavigationPath.append(title) }
                            )
                            
                            MovieHorizontalListView(
                                header: Constants.StringConstants.trendingTvShows,
                                movies: homeViewModel.trendingTVShows,
                                onSelect: { title in detailNavigationPath.append(title) }
                            )
                            
                            MovieHorizontalListView(
                                header: Constants.StringConstants.topRatedMovies,
                                movies: homeViewModel.topRatedMovies,
                                onSelect: { title in detailNavigationPath.append(title) }
                            )
                            
                            MovieHorizontalListView(
                                header: Constants.StringConstants.topRatedTvShows,
                                movies: homeViewModel.topRatedTVShows,
                                onSelect: { title in detailNavigationPath.append(title) }
                            )
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    
                case .error(let error):
                    ContentUnavailableView(
                        "Connection Error",
                        systemImage: "wifi.exclamationmark",
                        description: Text(error.localizedDescription)
                    )
                    .foregroundColor(.white)
                }
            }
            .task {
                await homeViewModel.getTitles()
            }
            .navigationDestination(for: TrendingModel.self) { title in
                MovieDetailView(title: title)
            }
        }
    }
}

#Preview {
    HomeView()
}
