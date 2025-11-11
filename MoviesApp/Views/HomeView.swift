//
//  HomeView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct HomeView: View {
    var heroBannerTitle = Constants.ImageConstants.heroBannerMovie
    var homeViewModel = HomeViewModel()
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                switch(homeViewModel.homeStatus){
                case .notstarted:
                    EmptyView()
                case .loading:
                    ProgressView()
                case .success:
                    LazyVStack {
                        AsyncImage(url: URL(string: heroBannerTitle)) {
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
                                
                            }label: {
                                Text(Constants.StringConstants.btnPlay)
                                    .ghostButton()
                            }
                            Button {
                                
                            }label: {
                                Text(Constants.StringConstants.btnDownload)
                                    .ghostButton()
                            }
                        }
                        HorizontalListView(header: Constants.StringConstants.trendingMovies,titles:homeViewModel.trendingMovies)
                        HorizontalListView(header: Constants.StringConstants.trendingTvShows,titles: homeViewModel.trendingMovies)
//                        HorizontalListView(header: Constants.StringConstants.topRatedMovies)
                        //                    HorizontalListView(header: Constants.StringConstants.topRatedTvShows)
                    }
                case .error(underlyingError: let error):
                    Text("Error from API : \(error.localizedDescription)")
                }
                
            }.task {
                await homeViewModel.getTrendingMovies()
            }
        }
    }
}

#Preview {
    HomeView()
}
