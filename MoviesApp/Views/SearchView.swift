//
//  SearchView.swift

//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchByMovies = true
    @State private var searchText = ""
    @State private var searchViewModel = SearchViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var selectedPlayableItem: UnifiedMediaItem? = nil
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var gridColumns: [GridItem] {
        #if os(tvOS)
        return [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 28)]
        #else
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)]
        } else {
            return [GridItem(.adaptive(minimum: 110), spacing: 16)]
        }
        #endif
    }
    
    private var isIPTVActive: Bool {
        IPTVDataManager.shared.homeStatus == .success && !IPTVDataManager.shared.availableTabs.isEmpty
    }
    
    var body: some View {
        ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    if let error = searchViewModel.errorMessage {
                        ContentUnavailableView("Search Error", systemImage: "exclamationmark.magnifyingglass", description: Text(error))
                    } else if isIPTVActive && searchText.isEmpty {
                        // Empty/Start state description for IPTV search
                        ContentUnavailableView {
                            Label("Search Content", systemImage: "magnifyingglass")
                        } description: {
                            Text("Find Live TV channels, movies, and series from your playlist instantly.")
                        }
                        .padding(.top, 60)
                    } else if isIPTVActive && searchViewModel.iptvResults.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView {
                            Label("No Matches Found", systemImage: "magnifyingglass")
                        } description: {
                            Text("No Live TV, Movies, or Series matching '\(searchText)' in your loaded playlist.")
                        }
                        .padding(.top, 60)
                    } else {
                        // Render Grid View
                        LazyVGrid(columns: gridColumns, spacing: horizontalSizeClass == .regular ? 20 : 16) {
                            if isIPTVActive {
                                ForEach(searchViewModel.iptvResults) { item in
                                    #if os(tvOS)
                                    Button {
                                        if item.mediaType == .movie || item.mediaType == .tvSeries {
                                            selectedPlayableItem = item
                                        } else {
                                            UserDataManager.shared.addToHistory(item)
                                            if let url = item.streamUrl {
                                                GlobalPlayerManager.shared.play(
                                                    url: url,
                                                    title: item.title,
                                                    artwork: item.posterPath,
                                                    isLive: item.mediaType == .liveTV,
                                                    streamId: item.id
                                                )
                                            } else {
                                                selectedPlayableItem = item
                                            }
                                        }
                                    } label: {
                                        UnifiedMediaCardView(item: item, width: 210)
                                    }
                                    .buttonStyle(.card)
                                    #else
                                    GeometryReader { geo in
                                        UnifiedMediaCardView(item: item, width: geo.size.width)
                                            .onTapGesture {
                                                #if os(iOS)
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                                #endif
                                                if item.mediaType == .movie || item.mediaType == .tvSeries {
                                                    selectedPlayableItem = item
                                                } else {
                                                    UserDataManager.shared.addToHistory(item)
                                                    if let url = item.streamUrl {
                                                        GlobalPlayerManager.shared.play(
                                                            url: url,
                                                            title: item.title,
                                                            artwork: item.posterPath,
                                                            isLive: item.mediaType == .liveTV,
                                                            streamId: item.id
                                                        )
                                                    } else {
                                                        selectedPlayableItem = item
                                                    }
                                                }
                                            }
                                    }
                                    .aspectRatio(2/3, contentMode: .fit)
                                    #endif
                                }
                            } else {
                                ForEach(searchViewModel.searchingMovies) { title in
                                    #if os(tvOS)
                                    Button {
                                        navigationPath.append(title)
                                    } label: {
                                        MovieCardView(movie: title, width: 210)
                                    }
                                    .buttonStyle(.card)
                                    #else
                                    GeometryReader { geo in
                                        MovieCardView(movie: title, width: geo.size.width)
                                            .onTapGesture {
                                                navigationPath.append(title)
                                            }
                                    }
                                    .aspectRatio(2/3, contentMode: .fit)
                                    #endif
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle(isIPTVActive ? "Search.." : (searchByMovies ? Constants.StringConstants.movieSearch : Constants.StringConstants.tvSearch))
            .toolbar {
                if !isIPTVActive {
                    #if os(iOS)
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            searchByMovies.toggle()
                            Task {
                                await searchViewModel.getSearchMovies(for: searchByMovies ? "movie" : "tv", searchPhase: searchText)
                            }
                        } label: {
                            Image(systemName: searchByMovies ? Constants.ImageConstants.movie : Constants.ImageConstants.tv)
                        }
                    }
                    #else
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            searchByMovies.toggle()
                            Task {
                                await searchViewModel.getSearchMovies(for: searchByMovies ? "movie" : "tv", searchPhase: searchText)
                            }
                        } label: {
                            Image(systemName: searchByMovies ? Constants.ImageConstants.movie : Constants.ImageConstants.tv)
                        }
                    }
                    #endif
                }
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                #endif
            }
            #if os(iOS)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Constants.StringConstants.search)
            #else
            .searchable(text: $searchText, prompt: Constants.StringConstants.search)
            #endif
            .task(id: searchText) {
                try? await Task.sleep(for: .milliseconds(300))
                
                if Task.isCancelled {
                    return
                }
                
                if isIPTVActive {
                    await searchViewModel.getSearchIPTV(searchPhase: searchText)
                } else {
                    await searchViewModel.getSearchMovies(for: searchByMovies ? "movie" : "tv", searchPhase: searchText)
                }
            }
            .navigationDestination(for: TrendingModel.self) { trendingModel in
                MovieDetailView(title: trendingModel)
            }
            .navigationDestination(item: $selectedPlayableItem) { item in
                if item.mediaType == .movie || item.mediaType == .tvSeries {
                    UnifiedMediaDetailView(item: item)
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
                    }
                }
        }
    }
}

#Preview {
    SearchView()
}
