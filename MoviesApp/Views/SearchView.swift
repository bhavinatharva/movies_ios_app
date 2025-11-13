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
    private var searchViewModel = SearchViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView{
                if let error = searchViewModel.errorMessage {
                    Text("Error \(error)")
                        .foregroundColor(.red)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 10))
                }
                
                LazyVGrid(columns: [GridItem(),GridItem(),GridItem()]) {
                    ForEach(searchViewModel.searchingMovies) { title in
                        AsyncImage(url: URL(string: title.posterPath ?? "")){ image in
                            image.resizable().scaledToFit().clipShape(.rect(cornerRadius: 10))
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 120,height: 200)
                        .onTapGesture {
                            navigationPath.append(title)
                        }
                        
                    }
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
