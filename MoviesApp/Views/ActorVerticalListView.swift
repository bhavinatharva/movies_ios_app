
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
            NavigationLink {
                // MovieDetailView(title: title)
            } label: {
                ActorRowView(title: title)
            }
        }
        .listStyle(PlainListStyle()) // Removes default list styling if needed
    }
}

struct ActorRowView: View {
    let title: ActorModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Image Section
            AsyncImage(url: URL(string: title.profilePath ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 150)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 150)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Text Content Section
            VStack(alignment: .leading, spacing: 8) {
                Text(title.name ?? "Unknown Name")
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(title.knownForDepartment ?? "Unknown Department")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(title.adult == true ? "18+" : "All Ages")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(title.adult == true ? .red : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((title.adult == true ? Color.red : Color.green).opacity(0.1))
                    )
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
        .frame(height: 140) // Fixed height for consistent rows
        .padding(.vertical, 4)
    }
}

#Preview {
    ActorVerticalListView(titles: ActorModel.previeTitles)
}
