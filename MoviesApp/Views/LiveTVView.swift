//
//  LiveTVView.swift
//  MoviesApp
//

import SwiftUI

struct LiveTVView: View {
    @State private var viewModel = LiveTVViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading Live TV...")
                        .tint(.white)
                        .foregroundColor(.white)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                        .foregroundColor(.white)
                } else {
                    HStack(spacing: 0) {
                        // Categories Sidebar (Vertical Scroll)
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(viewModel.categories) { category in
                                    Button(action: {
                                        viewModel.selectCategory(category)
                                    }) {
                                        Text(category.name)
                                            .font(.subheadline)
                                            .fontWeight(viewModel.selectedCategory?.id == category.id ? .bold : .regular)
                                            .foregroundColor(viewModel.selectedCategory?.id == category.id ? .white : .gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(viewModel.selectedCategory?.id == category.id ? Color.gray.opacity(0.3) : Color.clear)
                                    }
                                }
                            }
                        }
                        .frame(width: 120)
                        .background(Color.gray.opacity(0.1))
                        
                        // Channels List
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(viewModel.filteredChannels) { channel in
                                    NavigationLink(destination: StreamingPlayerView(url: channel.streamUrl, title: channel.name)) {
                                        HStack(spacing: 15) {
                                            if let logoUrl = channel.logoUrl {
                                                AsyncImage(url: logoUrl) { image in
                                                    image.resizable()
                                                         .scaledToFit()
                                                } placeholder: {
                                                    Image(systemName: "tv")
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 60, height: 40)
                                                .cornerRadius(4)
                                            } else {
                                                Image(systemName: "tv")
                                                    .frame(width: 60, height: 40)
                                                    .background(Color.gray.opacity(0.3))
                                                    .cornerRadius(4)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text(channel.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabLiveTV)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.categories.isEmpty {
                    await viewModel.loadData()
                }
            }
        }
    }
}
