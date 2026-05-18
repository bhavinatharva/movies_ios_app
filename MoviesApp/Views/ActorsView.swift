
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
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                switch actorViewModel.actorStatus {
                case .notstarted, .loading:
                    ProgressView()
                case .success:
                    ScrollView {
                        VStack(spacing: 24) {
                            if searchText.isEmpty {
                                ActorHeroHeaderView(actor: actorViewModel.popularActors.first) { actor in
                                    navigationPath.append(actor)
                                }
                                
                                ActorHorizontalListView(
                                    header: "Popular Actors",
                                    actors: actorViewModel.popularActors,
                                    onSelect: { actor in
                                        navigationPath.append(actor)
                                    }
                                )
                                
                                ActorHorizontalListView(
                                    header: "Trending This Week",
                                    actors: actorViewModel.trendingActors,
                                    onSelect: { actor in
                                        navigationPath.append(actor)
                                    }
                                )
                                
                                ActorHorizontalListView(
                                    header: "Known For",
                                    actors: actorViewModel.actorsData.shuffled(),
                                    onSelect: { actor in
                                        navigationPath.append(actor)
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
                }
            }
            .navigationDestination(for: ActorModel.self) { actor in
                ActorDetailView(actor: actor)
            }
            .navigationDestination(for: TrendingModel.self) { movie in
                MovieDetailView(title: movie)
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
    ActorsView()
}
