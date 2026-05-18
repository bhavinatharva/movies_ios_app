//
//  SearchView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI

struct SearchView: View {
    @State private var searchByMovies = true
    @State private var searchText = ""
    @State private var searchViewModel = SearchViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    if let error = searchViewModel.errorMessage {
                        ContentUnavailableView("Search Error", systemImage: "exclamationmark.magnifyingglass", description: Text(error))
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(searchViewModel.searchingMovies) { title in
                            MovieCardView(movie: title)
                                .onTapGesture {
                                    navigationPath.append(title)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(searchByMovies ? Constants.StringConstants.movieSearch : Constants.StringConstants.tvSearch)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            
                            searchByMovies.toggle()
                            
                            Task {
                                await searchViewModel.getSearchMovies(for: searchByMovies ? "movie":"tv", searchPhase: searchText)
                            }
                            
                        } label :{
                            Image(systemName:searchByMovies ? Constants.ImageConstants.movie : Constants.ImageConstants.tv)
                        }
                    }
                }
            .searchable(text: $searchText,prompt:Constants.StringConstants.search)
            .task(id: searchText) {
                try? await Task.sleep(for :.milliseconds(500))
                
                if Task.isCancelled {
                    return
                }
                
                await searchViewModel.getSearchMovies(for: searchByMovies ? "movie":"tv", searchPhase: searchText)
            }
            .navigationDestination(for: TrendingModel.self) { trendingModel in
                MovieDetailView(title: trendingModel)
            }
        }
    }
}

#Preview {
    SearchView()
}
