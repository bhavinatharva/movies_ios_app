//
//  RecentMoviesView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct RecentMoviesView: View {
    @State private var viewModel = RecentMoviesViewModel()
    
    var body: some View {

            ZStack {
                Color.black.ignoresSafeArea()
                
                Group {
                    switch viewModel.fetchStatus {
                    case .notstarted, .loading:
                        ProgressView("Loading recent changes...")
                            .tint(.white)
                    case .success:
                        if viewModel.recentChanges.isEmpty {
                            ContentUnavailableView("No Recent Changes", systemImage: "clock.badge.exclamationmark", description: Text("No movie changes found in the past 24 hours."))
                                .foregroundColor(.white)
                        } else {
                            List(viewModel.recentChanges) { change in
                                HStack {
                                    Image(systemName: "movieclapper")
                                        .foregroundColor(.accentColor)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Movie ID: \(String(change.id))")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        if let adult = change.adult {
                                            Text(adult ? "Adult Content" : "Standard Content")
                                                .font(.caption)
                                                .foregroundColor(adult ? .red : .secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Color.black)
                                .listRowSeparator(.visible, edges: .bottom)
                            }
                            .listStyle(.plain)
                        }
                    case .error(let error):
                        ContentUnavailableView("Error Loading Data", systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription))
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabRecent)
            .task {
                await viewModel.getRecentChanges()
            }
            .refreshable {
                await viewModel.getRecentChanges()
            }

    }
}

#Preview {
    RecentMoviesView()
}
