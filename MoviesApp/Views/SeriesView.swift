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
                            LazyVStack(spacing: 28) {
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
                                    
                                    // 4. Trending Series
                                    if !viewModel.trendingSeries.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Trending Series",
                                            items: viewModel.trendingSeries,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 5. Popular Series
                                    if !viewModel.popularSeries.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Popular Series",
                                            items: viewModel.popularSeries,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 6. Recommended For You
                                    if !viewModel.recommended.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Recommended For You",
                                            items: viewModel.recommended,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 7. Top Rated
                                    if !viewModel.topRated.isEmpty {
                                        UnifiedMediaListView(
                                            header: "Top Rated Series",
                                            items: viewModel.topRated,
                                            onSelect: { item in
                                                selectedDetailSeries = item
                                            }
                                        )
                                    }
                                    
                                    // 8. Vertical Genre Sections with Horizontal Sliders
                                    ForEach(viewModel.categories) { category in
                                        SeriesGenreRowView(category: category, viewModel: viewModel) { series in
                                            selectedDetailSeries = series
                                        }
                                    }
                                } else {
                                    // Search results grid view
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Search Results")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                        
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.filteredSeries) { series in
                                                GeometryReader { geo in
                                                    UnifiedMediaCardView(item: series, width: geo.size.width)
                                                        .onTapGesture {
                                                            selectedDetailSeries = series
                                                        }
                                                }
                                                .aspectRatio(3/4, contentMode: .fit)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.top, 12)
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

// MARK: - Lazy Loading Genre Row View for Series
struct SeriesGenreRowView: View {
    let category: XtreamCategory
    var viewModel: SeriesViewModel
    let onSelect: (UnifiedMediaItem) -> Void
    
    var body: some View {
        Group {
            if let items = viewModel.seriesByGenre[category.id] {
                if !items.isEmpty {
                    UnifiedMediaListView(
                        header: category.name,
                        items: items,
                        onSelect: onSelect
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appCardBackground)
                                    .frame(width: 140, height: 186.6)
                                    .overlay(
                                        ProgressView()
                                            .tint(.gray)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .task {
                    await viewModel.loadSeriesIfNeeded(for: category.id)
                }
            }
        }
    }
}
