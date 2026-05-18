
//
//  VerticalListView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI
import SwiftData

struct ActorVerticalListView: View {
    var titles: [ActorModel]
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        List(titles) { title in
            ZStack {
                NavigationLink {
                    ActorDetailView(actor: title)
                } label: {
                    EmptyView()
                }
                .opacity(0)
                
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: title.profilePath ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 150)
                            .cardStyle()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 100, height: 150)
                            .shimmer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title.name ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(title.knownForDepartment ?? "")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        
                        if let knownFor = title.knownFor?.prefix(2) {
                            Text(knownFor.compactMap { $0.title ?? $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            if title.adult == true {
                                Text("18+")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.red, lineWidth: 1))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(Color.appBackground)
            .listRowSeparator(.visible, edges: .bottom)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
        .background(Color.appBackground)
    }
}

#Preview {
    ActorVerticalListView(titles: ActorModel.previeTitles)
}
