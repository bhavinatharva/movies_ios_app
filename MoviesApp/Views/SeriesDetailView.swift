//
//  SeriesDetailView.swift
//  MoviesApp
//

import SwiftUI

struct SeriesDetailView: View {
    let series: UnifiedMediaItem
    
    @State private var seasons: [String] = []
    @State private var selectedSeason: String = ""
    @State private var episodes: [String: [XtreamEpisode]] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedEpisode: XtreamEpisode?
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
    private var isM3USeries: Bool {
        series.id.hasPrefix("m3useries_")
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 0) {
                    Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 200).shimmer()
                    VStack(alignment: .leading, spacing: 16) {
                        Rectangle().fill(Color.gray.opacity(0.15)).frame(width: 200, height: 30).shimmer()
                        Rectangle().fill(Color.gray.opacity(0.15)).frame(width: 150, height: 20).shimmer()
                        Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 80).shimmer()
                    }
                    .padding()
                    Spacer()
                }
            } else if let error = errorMessage {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                VStack(spacing: 0) {
                    // Header cover / Banner
                    AsyncImage(url: URL(string: series.posterPath ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .netflixStyleGradient()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .shimmer()
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(series.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        if !seasons.isEmpty {
                            Menu {
                                ForEach(seasons, id: \.self) { season in
                                    Button(action: {
                                        selectedSeason = season
                                    }) {
                                        HStack {
                                            Text("Season \(season)")
                                            if selectedSeason == season {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Season \(selectedSeason)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(6)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Episodes List
                    if let currentEpisodes = episodes[selectedSeason] {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(currentEpisodes, id: \.id) { episode in
                                    Button(action: {
                                        playEpisode(episode)
                                    }) {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: URL(string: episode.info?.movieImage ?? "")) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 60)
                                                    .cornerRadius(6)
                                                    .clipped()
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 100, height: 60)
                                                    .shimmer()
                                                    .overlay(
                                                        Image(systemName: "play.fill")
                                                            .foregroundColor(.white)
                                                    )
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(episode.episodeNum ?? 0). \(episode.title)")
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                    .multilineTextAlignment(.leading)
                                                
                                                if let plot = episode.info?.plot {
                                                    Text(plot)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    } else {
                        Spacer()
                        Text("No episodes in this season")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(series.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSeriesInfo()
        }
        .fullScreenCover(item: $selectedEpisode) { _ in
            ZStack(alignment: .topTrailing) {
                Color.appBackground.ignoresSafeArea()
                
                ContentUnavailableView {
                    Label("Cannot Play", systemImage: "play.slash")
                } description: {
                    Text("No playable link found for this episode.")
                        .foregroundColor(.secondary)
                } actions: {
                    Button(action: {
                        selectedEpisode = nil
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
                    selectedEpisode = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.6))
                        .padding()
                }
            }
        }
    }
    
    private func loadSeriesInfo() async {
        if isM3USeries {
            let cached = IPTVDataManager.shared.m3uEpisodes[series.id] ?? [:]
            await MainActor.run {
                self.episodes = cached
                self.seasons = cached.keys.sorted {
                    let s1 = Int($0) ?? 0
                    let s2 = Int($1) ?? 0
                    return s1 < s2
                }
                self.selectedSeason = self.seasons.first ?? ""
                self.isLoading = false
            }
            return
        }
        
        guard let creds = authManager.credentials,
              let seriesId = Int(series.id) else {
            errorMessage = "Invalid credentials or Series ID"
            isLoading = false
            return
        }
        
        do {
            let response = try await iptvService.fetchSeriesInfo(creds: creds, seriesId: seriesId)
            await MainActor.run {
                self.episodes = response.episodes
                self.seasons = response.episodes.keys.sorted {
                    let s1 = Int($0) ?? 0
                    let s2 = Int($1) ?? 0
                    return s1 < s2
                }
                self.selectedSeason = self.seasons.first ?? ""
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func getNextEpisodeInfo(for episode: XtreamEpisode) -> (title: String, action: () -> Void)? {
        guard let episodesList = episodes[selectedSeason],
              let currentIndex = episodesList.firstIndex(where: { $0.id == episode.id }),
              currentIndex + 1 < episodesList.count else {
            return nil
        }
        
        let nextEp = episodesList[currentIndex + 1]
        let title = "\(nextEp.episodeNum ?? 0). \(nextEp.title)"
        return (title: title, action: {
            self.playEpisode(nextEp)
        })
    }
    
    private func playEpisode(_ episode: XtreamEpisode) {
        let nextInfo = getNextEpisodeInfo(for: episode)
        
        var resolvedUrl: URL? = nil
        if isM3USeries {
            resolvedUrl = URL(string: episode.id)
        } else if let creds = authManager.credentials {
            resolvedUrl = URL(string: "\(creds.serverUrl)/series/\(creds.username)/\(creds.password)/\(episode.id).\(episode.containerExtension)")
        }
        
        if let streamUrl = resolvedUrl {
            GlobalPlayerManager.shared.play(
                url: streamUrl,
                title: episode.title,
                artwork: nil,
                isLive: false,
                streamId: episode.id,
                subtitle: nil,
                nextEpisodeTitle: nextInfo?.title,
                onPlayNext: nextInfo?.action
            )
        } else {
            selectedEpisode = episode
        }
    }
}

extension XtreamEpisode: Identifiable {}
