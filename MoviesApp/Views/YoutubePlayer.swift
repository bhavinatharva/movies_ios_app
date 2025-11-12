//
//  YoutubePlayer.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI
import WebKit

struct YoutubePlayer :UIViewRepresentable {
    let webview = WKWebView()
    let videoId : String
    let youtubeBaseUrl = ApiConfig.shared?.youtubeBaseUrl
    
    func makeUIView(context : Context ) -> some UIView {
        webview
    }
    
    func updateUIView(_ uiView :UIViewType, context :Context)  {
        guard let baseYoutubeURL = youtubeBaseUrl,
              let baseURL = URL(string: baseYoutubeURL)else {return}
        let fullURL = baseURL.appending(path: videoId)
        print("fullURL \(fullURL)")
        webview.load(URLRequest(url: fullURL))
    }
}
