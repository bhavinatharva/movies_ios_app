//
//  SeriesView.swift
//  MoviesApp
//

import SwiftUI

struct SeriesView: View {
    @State private var viewModel = SeriesViewModel()
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search series...", text: $viewModel.searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading Categories...")
                            .tint(.white)
                            .foregroundColor(.white)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                            .foregroundColor(.white)
                    } else {
                        // Category Horizontal Bar
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
                                            .background(viewModel.selectedCategory?.id == category.id ? Color.accentColor : Color.gray.opacity(0.2))
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        
                        if viewModel.isLoadingSeries {
                            Spacer()
                            ProgressView("Loading Series...")
                                .tint(.white)
                                .foregroundColor(.white)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(viewModel.filteredSeries) { series in
                                        NavigationLink(destination: SeriesDetailView(series: series)) {
                                            UnifiedMediaCardView(item: series)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabSeries)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.categories.isEmpty {
                    await viewModel.loadCategories()
                }
            }
        }
    }
}
