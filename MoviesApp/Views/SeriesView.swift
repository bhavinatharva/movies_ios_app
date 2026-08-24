//
//  SeriesView.swift
//  MoviesApp
//

import SwiftUI

struct SeriesView: View {
    @State private var viewModel = SeriesViewModel()
    @State private var selectedDetailSeries: UnifiedMediaItem?
    
    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Skeleton Hero Header
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 450)
                                    .shimmer()
                                
                                // Skeleton Rails
                                ForEach(0..<3, id: \.self) { _ in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 140, height: 20)
                                            .padding(.horizontal, 16)
                                            .shimmer()
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(0..<4, id: \.self) { _ in
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.gray.opacity(0.1))
                                                        .frame(width: 140, height: 210)
                                                        .shimmer()
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                    } else {
                        ScrollView {
                            if let category = viewModel.selectedCategory {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 16)], spacing: 16) {
                                    ForEach(viewModel.seriesByGenre[category.id] ?? []) { series in
                                        GeometryReader { geo in
                                            UnifiedMediaCardView(item: series, width: geo.size.width)
                                                .onTapGesture {
                                                    selectedDetailSeries = series
                                                }
                                        }
                                        .aspectRatio(3/4, contentMode: .fit)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            } else {
                                homeRailsView
                            }
                        }
                        .ignoresSafeArea(edges: viewModel.selectedCategory == nil ? .top : .init())
                    }
                }
            }
            .navigationTitle(viewModel.selectedCategory?.categoryName ?? Constants.StringConstants.tabSeries)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Menu {
                        Button("All (Home)") {
                            viewModel.selectedCategory = nil
                        }
                        
                        ForEach(viewModel.categories, id: \.id) { category in
                            Button(category.categoryName ?? category.id) {
                                viewModel.selectedCategory = category
                                Task {
                                    await viewModel.loadSeriesIfNeeded(for: category.id)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
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
    
    @ViewBuilder
    private var homeRailsView: some View {
        LazyVStack(spacing: 28) {
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
        }
        .padding(.bottom, 30) // Clear tab bar space
    }
                            }
                        }
                        .ignoresSafeArea(edges: viewModel.selectedCategory == nil ? .top : .init())
                    }
                }
            }
            .navigationTitle(viewModel.selectedCategory?.categoryName ?? Constants.StringConstants.tabSeries)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Menu {
                        Button("All (Home)") {
                            viewModel.selectedCategory = nil
                        }
                        
                        ForEach(viewModel.categories, id: \.id) { category in
                            Button(category.categoryName ?? category.id) {
                                viewModel.selectedCategory = category
                                Task {
                                    await viewModel.loadSeriesIfNeeded(for: category.id)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
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
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 140, height: 186.6)
                                    .shimmer()
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
