//
//  HorizontalListView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct HorizontalListView: View {
    let header : String
    let titles : [TrendingModel]
    let onSelect : (TrendingModel) -> Void
    var body: some View {
        VStack(alignment: .leading) {
            Text(header).font(.title)
            ScrollView (.horizontal) {
                LazyHStack{
                    ForEach(titles) { title in
                        
                        ZStack(alignment: .topTrailing) {
                            AsyncImage(url: URL(string: title.posterPath ?? ""))
                            {image in image
                                    .resizable()
                                    .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 10))}
                            placeholder: {
                                ProgressView()
                            }
                            .frame(width: 120,height: 200)
                            .onTapGesture {
                                onSelect(title)
                            }
                            if title.adult == true {
                                Text("18+")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .offset(x: -8, y: 8)
                            }
                        }
                    }}
            }
        }.frame(height: 250).padding(10)
    }
}

#Preview {
    HorizontalListView(header : Constants.StringConstants.trendingMovies, titles: TrendingModel.previeTitles, onSelect:{title in } )
}
