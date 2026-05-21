//
//  AdultView.swift
//  MoviesApp
//

import SwiftUI

struct AdultView: View {
    @State private var viewModel = AdultViewModel()
    @State private var selectedPlayableItem: UnifiedMediaItem?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search adult content...", text: $viewModel.searchText)
                        .foregroundColor(.primary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)
                .background(Color.appCardBackground)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Segmented Tab Picker
                Picker("Tabs", selection: $viewModel.selectedTab) {
                    ForEach(AdultViewModel.AdultTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Adult Content...")
                        .tint(.red)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Error Loading", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    let items = currentItems
                    
                    if items.isEmpty {
                        ContentUnavailableView {
                            Label("No Adult Content Found", systemImage: "eye.slash.fill")
                        } description: {
                            Text("No adult categories or titles found in your loaded IPTV playlist.")
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(items) { item in
                                    UnifiedMediaCardView(item: item, width: nil)
                                        .onTapGesture {
                                            UserDataManager.shared.addToHistory(item)
                                            selectedPlayableItem = item
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .navigationTitle("Adult (18+)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAdultContent()
        }
        .fullScreenCover(item: $selectedPlayableItem) { item in
            if item.mediaType == .movie || item.mediaType == .tvSeries {
                UnifiedMediaDetailView(item: item)
            } else if let url = item.streamUrl {
                StreamingPlayerView(url: url, title: item.title, streamId: item.id)
            } else {
                ZStack(alignment: .topTrailing) {
                    Color.appBackground.ignoresSafeArea()
                    
                    ContentUnavailableView {
                        Label("Cannot Play", systemImage: "play.slash")
                    } description: {
                        Text("No streamable link found for this item.")
                            .foregroundColor(.secondary)
                    } actions: {
                        Button(action: {
                            selectedPlayableItem = nil
                        }) {
                            Text("Close")
                                .fontWeight(.bold)
                                .frame(width: 120, height: 44)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    
                    Button(action: {
                        selectedPlayableItem = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }
            }
        }
    }
    
    private var currentItems: [UnifiedMediaItem] {
        switch viewModel.selectedTab {
        case .live:
            return viewModel.filteredChannels
        case .movies:
            return viewModel.filteredMovies
        case .series:
            return viewModel.filteredSeries
        }
    }
}
