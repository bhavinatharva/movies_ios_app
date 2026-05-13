//
//  DownloadView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 13/11/25.
//

import SwiftUI
import SwiftData

struct DownloadView: View {
    @Query var savedTitled : [TrendingModel]
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if savedTitled.isEmpty {
                    ContentUnavailableView(
                        "No Downloads",
                        systemImage: "arrow.down.circle",
                        description: Text("Movies and TV shows you download will appear here.")
                    )
                    .foregroundColor(.white)
                } else {
                    VerticalListView(titles: savedTitled, canDelete: true)
                }
            }
            .navigationTitle(Constants.StringConstants.tabDownloads)
        }
    }
}

#Preview {
    DownloadView()
}
