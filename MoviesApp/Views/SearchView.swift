//
//  SearchView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI

struct SearchView: View {
    var titles = TrendingModel.previeTitles
    @State private var searchByMovies = true
    var body: some View {
        NavigationStack {
            ScrollView{
                LazyVGrid(columns: [GridItem(),GridItem(),GridItem()]) {
                    ForEach(titles) { title in
                        AsyncImage(url: URL(string: title.posterPath ?? "")){ image in
                            image.resizable().scaledToFit().clipShape(.rect(cornerRadius: 10))
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 120,height: 200)
                        
                    }
                }
            }.navigationTitle(searchByMovies ? Constants.StringConstants.movieSearch : Constants.StringConstants.tvSearch)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            searchByMovies.toggle()
                        } label :{
                            Image(systemName:searchByMovies ? Constants.ImageConstants.movie : Constants.ImageConstants.tv)
                        }
                    }
                }
        }
    }
}

#Preview {
    SearchView()
}
