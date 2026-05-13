
//
//  UpcomingView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct ActorsView: View {
    
    var actorViewModel = ActorsViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch actorViewModel.actorStatus {
                case .notstarted, .loading:
                    ProgressView()
                        .tint(.white)
                case .success:
                    ScrollView {
                        VStack(spacing: 24) {
                            if searchText.isEmpty {
                                ActorHeroHeaderView(actor: actorViewModel.popularActors.first)
                                
                                ActorHorizontalListView(
                                    header: "Popular Actors",
                                    actors: actorViewModel.popularActors,
                                    onSelect: { actor in
                                        // Handle selection
                                    }
                                )
                                
                                ActorHorizontalListView(
                                    header: "Trending This Week",
                                    actors: actorViewModel.trendingActors,
                                    onSelect: { actor in
                                        // Handle selection
                                    }
                                )
                                
                                ActorHorizontalListView(
                                    header: "Known For",
                                    actors: actorViewModel.actorsData.shuffled(),
                                    onSelect: { actor in
                                        // Handle selection
                                    }
                                )
                            } else {
                                // Search results view
                                ActorVerticalListView(titles: actorViewModel.actorsData)
                                    .padding(.top, 60) // Offset for search bar space
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    
                case .error(let error):
                    ContentUnavailableView(
                        "Connection Error",
                        systemImage: "wifi.exclamationmark",
                        description: Text(error.localizedDescription)
                    )
                    .foregroundColor(.white)
                }
            }
            .task {
                await actorViewModel.getActors(searchPhase: "")
            }
            .searchable(text: $searchText, prompt: Constants.StringConstants.search)
            .task(id: searchText) {
                if !searchText.isEmpty {
                    try? await Task.sleep(for: .milliseconds(500))
                    if !Task.isCancelled {
                        await actorViewModel.getActors(searchPhase: searchText)
                    }
                }
            }
        }
    }
}

#Preview {
    UpcomingView()
}
