//
//  MovieDetailView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI

struct MovieDetailView: View {
    
    let title : TrendingModel
    var titleName : String  {
        return (title.name ?? title.title) ?? ""
    }
    var body: some View {
        GeometryReader {geo in
            ScrollView{
                LazyVStack(alignment: .leading) {
                    AsyncImage(url: URL(string: title.posterPath ?? "")) {image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }.frame(width: geo.size.width,height: geo.size.height*0.85)
                    
                    Text(titleName).bold().font(.title2).padding(5)
                    Text(title.overview ?? "").font(.title2).padding(5)
                    
                    HStack {
                        Spacer()
                        Button {
                            
                        } label: {
                            Text(Constants.StringConstants.btnDownload).ghostButton()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    MovieDetailView(title: TrendingModel.previeTitles[0])
}
