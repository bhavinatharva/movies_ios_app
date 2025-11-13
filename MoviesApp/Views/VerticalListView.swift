//
//  VerticalListView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI
import SwiftData

struct VerticalListView: View {
    var titles :[TrendingModel]
    var canDelete : Bool
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        List(titles) { title in
            NavigationLink {
                MovieDetailView(title: title)
            } label: {
                AsyncImage(url: URL(string: title.posterPath ?? "")) {image in
                    HStack {
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 10))
                            .padding(5)
                        
                        VStack {
                            Text((title.name ?? title.title) ?? "")
                                .font(.system(size:14))
                                .bold()
                            Text(title.overview ?? "")
                                .font(.system(size:12))
                            
                        }
                    }} placeholder: {
                        ProgressView()
                    }
                    .frame(height: 150)
            }
            .swipeActions(edge: .trailing) {
                if canDelete {
                    Button {
                        modelContext.delete(title)
                        try? modelContext.save()
                    } label: {
                        Image(systemName: Constants.ImageConstants.trash)
                            .tint(.red)
                        
                    }
                }
            }
        }
    }
}

#Preview {
    VerticalListView(titles: TrendingModel.previeTitles, canDelete: true)
}
