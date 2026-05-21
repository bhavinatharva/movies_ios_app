//
//  VODView.swift
//  MoviesApp
//

import SwiftUI

struct VODView: View {
    @State private var selectedSegment: VODSegment = .movies
    
    enum VODSegment: String, CaseIterable {
        case movies = "Movies"
        case series = "Series"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()
            
            // Content Layer
            VStack(spacing: 0) {
                if selectedSegment == .movies {
                    VODMoviesView()
                } else {
                    SeriesView()
                }
            }
            .padding(.top, 60) // Space for floating picker
            
            // Floating Segmented Picker
            VStack {
                Picker("VOD Type", selection: $selectedSegment) {
                    ForEach(VODSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, 8)
            }
        }
    }
}
