
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
            GeometryReader { geo in
                switch actorViewModel.actorStatus {
                case ApiFetchStatus.notstarted:
                    EmptyView()
                case ApiFetchStatus.loading:
                    ProgressView()
                        .frame(width: geo.size.width,height: geo.size.height)
                case ApiFetchStatus.success:
                    ActorVerticalListView(titles:actorViewModel.actorsData)
                        .navigationDestination(for: ActorModel.self) { title in
//                            MovieDetailView(title: title)
                        }
                    
                case ApiFetchStatus.error(underlyingError: let error):
                    Text("Error from API : \(error.localizedDescription)")
                }
            }
            
            .task {
                await actorViewModel.getActors(searchPhase:     "" )
            }
        }
        .searchable(text: $searchText,prompt:Constants.StringConstants.search)
        .task(id: searchText) {
            try? await Task.sleep(for :.milliseconds(500))
            
            if Task.isCancelled {
                return
            }
            
            await actorViewModel.getActors(searchPhase: searchText)
        }
    }
}

#Preview {
    UpcomingView()
}
