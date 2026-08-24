
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
                    ScrollView {
                        VStack(spacing: 24) {
                            Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 450).shimmer()
                            ForEach(0..<3, id: \.self) { _ in
                                VStack(alignment: .leading, spacing: 12) {
                                    Rectangle().fill(Color.gray.opacity(0.15)).frame(width: 140, height: 20).padding(.horizontal, 16).shimmer()
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(0..<4, id: \.self) { _ in
                                                RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)).frame(width: 140, height: 210).shimmer()
                                            }
                                        }.padding(.horizontal, 16)
                                    }
                                }
                            }
                        }.padding(.bottom, 40)
                    }
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
        }
    }
}
#Preview {
    ActorsView()
}
