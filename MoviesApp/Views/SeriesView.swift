//
//  SeriesView.swift
//  MoviesApp
//

import SwiftUI

struct SeriesView: View {
    @State private var viewModel = SeriesViewModel()
    @State private var selectedDetailSeries: UnifiedMediaItem?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search series...", text: $viewModel.searchText)
                            .foregroundColor(.primary)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(10)
                    .background(Color.appCardBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading Categories...")
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                if viewModel.searchText.isEmpty {
                                    // 1. Featured Hero Series
                                    if let hero = viewModel.heroSeries {
                                        IPTVHeroHeaderView(item: hero) {
                                            selectedDetailSeries = hero
                                        }
                                    }
                                    
                                    // 2. Continue Watching
                                    if !viewModel.continueWatching.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Continue Watching",
                                            items: viewModel.continueWatching,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 3. Recently Added Episodes
                                    if !viewModel.recentlyAdded.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Recently Added Episodes",
                                            items: viewModel.recentlyAdded,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                }
                                
                                // 4. Genre Filters
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.categories) { category in
                                            Button(action: {
                                                viewModel.selectCategory(category)
                                            }) {
                                                Text(category.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(viewModel.selectedCategory?.id == category.id ? Color.accentColor : Color.appCardBackground)
                                                    .foregroundColor(viewModel.selectedCategory?.id == category.id ? .white : .primary)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical, 8)
                                
                                if viewModel.searchText.isEmpty {
                                    // 5. Trending Series
                                    if !viewModel.trendingSeries.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Trending Series",
                                            items: viewModel.trendingSeries,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 6. Popular Series
                                    if !viewModel.popularSeries.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Popular Series",
                                            items: viewModel.popularSeries,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 7. Recommended For You
                                    if !viewModel.recommended.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Recommended For You",
                                            items: viewModel.recommended,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 8. Top Rated
                                    if !viewModel.topRated.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Top Rated Series",
                                            items: viewModel.topRated,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                }
                                
                                // 9. Full Browse Grid
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(viewModel.selectedCategory?.name ?? "Browse Series")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                    
                                    if viewModel.isLoadingSeries {
                                        ProgressView("Loading series...")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 24)
                                    } else {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.filteredSeries) { series in
                                                NavigationLink(destination: SeriesDetailView(series: series)) {
                                                    UnifiedMediaCardView(item: series, width: nil)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 30) // Clear tab bar space
                        }
                        .ignoresSafeArea(edges: .top)
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabSeries)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedDetailSeries) { series in
                SeriesDetailView(series: series)
            }
            .task {
                if viewModel.categories.isEmpty {
                    await viewModel.loadCategories()
                }
            }
        }
    }
}
