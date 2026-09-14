//
//  UnifiedMediaDetailView.swift

//

import SwiftUI

struct UnifiedMediaDetailView: View {
    @State private var viewModel: UnifiedMediaDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    init(item: UnifiedMediaItem) {
        _viewModel = State(initialValue: UnifiedMediaDetailViewModel(item: item))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Cinematic Header (Backdrop + Floating Poster)
                    headerSection
                    
                    // Metadata & Action Buttons
                    metadataSection
                    
                    // Overview
                    if let overview = viewModel.item.overview, !overview.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Overview")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(overview)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Trailer
                    if let trailerUrl = viewModel.item.trailerUrl {
                        trailerSection(url: trailerUrl)
                    }
                    
                    // Director & Cast
                    castAndCrewSection
                    
                    // Related Content
                    if !viewModel.relatedMovies.isEmpty {
                        relatedContentSection
                    }
                    
                    Spacer(minLength: 60)
                }
            }
            .ignoresSafeArea(edges: .top)
            .task {
                await viewModel.loadDetails()
            }
            
            // Custom Dismiss Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            let backdropUrl = viewModel.item.backdropPath ?? viewModel.item.posterPath ?? ""
            if let url = URL(string: backdropUrl), !backdropUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: 500)
                            .clipped()
                    case .empty, .failure:
                        fallbackHero
                    @unknown default:
                        fallbackHero
                    }
                }
                .overlay(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .clear, location: 0.4),
                            Gradient.Stop(color: Color.appBackground, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                fallbackHero
            }
            
            // Floating Poster
            HStack(alignment: .bottom, spacing: 16) {
                if let posterStr = viewModel.item.posterPath, let posterUrl = URL(string: posterStr) {
                    AsyncImage(url: posterUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 210)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)
                        default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                                .frame(width: 140, height: 210)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.item.title)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .shadow(radius: 2)
                    
                    if viewModel.isLoading {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 120, height: 16)
                            .padding(.top, 4)
                            .shimmer()
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .offset(y: 40) // Push it slightly down over the gradient
        }
        .padding(.bottom, 40) // Make space for the offset poster
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Details Row (Rating, Year, Duration, Country)
            HStack(spacing: 12) {
                
                if let releaseDate = viewModel.item.releaseDate, !releaseDate.isEmpty {
                    Text(releaseDate.prefix(4)) // Just show year for cleaner look
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                if let runtime = viewModel.item.runtime {
                    Text("\(runtime)m")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                if let rating = viewModel.item.voteAverage, rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                
                if let country = viewModel.item.country, !country.isEmpty {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Genres
            if let genres = viewModel.item.genres, !genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1)) // Glassmorphic feel
                                .cornerRadius(20)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .horizontalScrollFix()
            }
            
            // Play Button
            Button(action: {
                UserDataManager.shared.addToHistory(viewModel.item)
                if let url = viewModel.item.streamUrl {
                    GlobalPlayerManager.shared.play(
                        url: url,
                        title: viewModel.item.title,
                        artwork: nil,
                        isLive: false,
                        streamId: viewModel.item.id
                    )
                }
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    Text("Play \(viewModel.item.mediaType == .tvSeries ? "Series" : "Movie")")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(.horizontal, 20)
        }
    }
    
    private func trailerSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trailer")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
            
            Link(destination: url) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCardBackground)
                        .frame(height: 180)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 4)
                    
                    VStack {
                        Spacer()
                        HStack {
                            Text("Watch Official Trailer")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
        }
    }
    
    private var castAndCrewSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Director row
            if let director = viewModel.item.director, !director.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Director")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(director)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
            }

            // Cast section — prefer TMDB (has photos + character names) over IPTV string
            let hasTMDBCast = !viewModel.tmdbCastMembers.isEmpty
            let hasIPTVCast = !(viewModel.item.cast ?? "").isEmpty

            if hasTMDBCast || hasIPTVCast || viewModel.isLoading {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cast")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {

                            // ── TMDB cast (rich: photo + character name) ──
                            if hasTMDBCast {
                                ForEach(viewModel.tmdbCastMembers) { member in
                                    castCard(
                                        imageURL: member.profileImageURL,
                                        name: member.name,
                                        subtitle: member.character.isEmpty ? nil : member.character
                                    )
                                }

                            // ── Loading skeleton while TMDB fetch is in flight ──
                            } else if viewModel.isLoading {
                                ForEach(0..<8, id: \.self) { _ in
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(UIColor.secondarySystemFill))
                                            .frame(width: 80, height: 80)
                                            .shimmer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(UIColor.secondarySystemFill))
                                            .frame(width: 72, height: 12)
                                            .shimmer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(UIColor.tertiarySystemFill))
                                            .frame(width: 56, height: 10)
                                            .shimmer()
                                    }
                                }

                            // ── IPTV string fallback (name only, no photo) ──
                            } else if hasIPTVCast, let castStr = viewModel.item.cast {
                                ForEach(castStr.parseCastMembers(role: "Actor")) { actor in
                                    castCard(
                                        imageURL: actor.imageUrl,
                                        name: actor.name,
                                        subtitle: nil
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                    .horizontalScrollFix()
                }
            }
        }
    }

    /// Reusable card used by both TMDB and IPTV cast rows.
    @ViewBuilder
    private func castCard(imageURL: URL?, name: String, subtitle: String?) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color(UIColor.secondarySystemFill))
                        .frame(width: 80, height: 80)
                        .shimmer()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                case .failure, _:
                    Circle()
                        .fill(Color(UIColor.secondarySystemFill))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.secondary)
                                .font(.title2)
                        )
                }
            }

            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 84)

            if let subtitle = subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 84)
            }
        }
    }
    
    private var relatedContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More Like This")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.relatedMovies) { movie in
                        NavigationLink(destination: UnifiedMediaDetailView(item: movie)) {
                            VStack(alignment: .leading) {
                                if let posterUrl = URL(string: movie.posterPath ?? "") {
                                    AsyncImage(url: posterUrl) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 110, height: 165)
                                                .cornerRadius(8)
                                        default:
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.appCardBackground)
                                                .frame(width: 110, height: 165)
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appCardBackground)
                                        .frame(width: 110, height: 165)
                                }
                                
                                Text(movie.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(width: 110, alignment: .leading)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            .horizontalScrollFix()
        }
    }
    
    private var fallbackHero: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 500)
            
            Image(systemName: "film.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.1))
        }
    }
}
