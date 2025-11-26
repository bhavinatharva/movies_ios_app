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
            GeometryReader { geo in
                ScrollView {
                    switch(homeViewModel.homeStatus){
                    case .notstarted:
                        EmptyView()
                    case .loading:
                        ProgressView()
                            .frame(width: geo.size.width,height: geo.size.height)
                    case .success:
                        LazyVStack {
                            AsyncImage(url: URL(string: homeViewModel.heroTitle.posterPath ?? "")) {
                                image in
                                image
                                    .resizable()
                                    .scaledToFit().overlay{
                                        LinearGradient (
                                            stops: [
                                                Gradient.Stop(color: .clear, location: 0.8),
                                                Gradient.Stop(color: .gradient, location: 1)
                                            ],
                                            startPoint: .top, endPoint: .bottom)
                                    }
                            } placeholder: {
                                ProgressView()
                            }.frame(width: geo.size.width,height: geo.size.height*0.85)
                            HStack {
                                Button {
                                    detailNavigationPath.append(homeViewModel.heroTitle)
                                }label: {
                                    Text(Constants.StringConstants.btnPlay)
                                        .ghostButton()
                                }
                                Button {
                                    modelContext.insert(homeViewModel.heroTitle)
                                    try? modelContext.save()
                                    
                                }label: {
                                    Text(Constants.StringConstants.btnDownload)
                                        .ghostButton()
                                }
                            }
                            HorizontalListView(header: Constants.StringConstants.nowPlayingMovies,
                                               titles:homeViewModel.nowPlayingMovies, onSelect: {title in detailNavigationPath.append(title)})
                            HorizontalListView(header: Constants.StringConstants.popularMovies,titles:homeViewModel.popularMovies, onSelect: {title in detailNavigationPath.append(title)})
                            HorizontalListView(header: Constants.StringConstants.trendingMovies,titles:homeViewModel.trendingMovies, onSelect: {title in detailNavigationPath.append(title)})
                            HorizontalListView(header: Constants.StringConstants.trendingTvShows,titles: homeViewModel.trendingTVShows, onSelect: {title in  detailNavigationPath.append(title)})
                            HorizontalListView(header: Constants.StringConstants.topRatedMovies,titles: homeViewModel.topRatedMovies, onSelect: {title in detailNavigationPath.append(title)})
                            HorizontalListView(header: Constants.StringConstants.topRatedTvShows,titles: homeViewModel.topRatedTVShows, onSelect: {title in detailNavigationPath.append(title)})
                        }
                        .navigationDestination(for: TrendingModel.self) { title in
                            MovieDetailView(title: title)
                        }
                    case .error(underlyingError: let error):
                        Text("Error from API : \(error.localizedDescription)")
                    }
                    
                }.task {
                    await homeViewModel.getTitles()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
