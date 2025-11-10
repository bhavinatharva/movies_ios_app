//
//  HorizontalListView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct HorizontalListView: View {
    let header : String
    let titles = [Constants.ImageConstants.image1,Constants.ImageConstants.image2,Constants.ImageConstants.image3,Constants.ImageConstants.image4]
    var body: some View {
        VStack(alignment: .leading) {
            Text(header).font(.title)
            ScrollView (.horizontal) {
                LazyHStack{
                    ForEach(titles,id: \.self){title in
                        AsyncImage(url: URL(string: title)) {image in image.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 10))}placeholder: {
                            ProgressView()
                        }}.frame(width: 120,height: 200)
                }
            }
        }.frame(height: 250).padding(10)
    }
}

#Preview {
    HorizontalListView(header : Constants.StringConstants.trendingMovies)
}
