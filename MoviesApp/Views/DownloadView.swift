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
            if savedTitled.isEmpty {
                Text("No Downloads")
                    .font(.title3)
                    .padding()
                    .bold()
            }else {
                VerticalListView(titles: savedTitled,canDelete: true)
            }
        }
    }
}

#Preview {
    DownloadView()
}
