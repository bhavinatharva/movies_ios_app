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
            ZStack {
                NavigationLink {
                    MovieDetailView(title: title)
                } label: {
                    EmptyView()
                }
                .opacity(0)
                
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: title.posterPath ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 150)
                            .cardStyle()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 100, height: 150)
                            .shimmer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text((title.name ?? title.title) ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(title.overview ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                        
                        HStack {
                            if title.adult == true {
                                Text("18+")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.red, lineWidth: 1))
                            }
                            
                            Text(title.release_date ?? "")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "play.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .listRowBackground(Color.black)
            .listRowSeparator(.visible, edges: .bottom)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .swipeActions(edge: .trailing) {
                if canDelete {
                    Button(role: .destructive) {
                        modelContext.delete(title)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: Constants.ImageConstants.trash)
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.black)
    }
}

#Preview {
    VerticalListView(titles: TrendingModel.previeTitles, canDelete: true)
}
