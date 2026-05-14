//
//  YoutubePlayer.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI
import WebKit

struct YoutubePlayer: UIViewRepresentable {
    let videoId: String
    let showControls: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString = """
               <!DOCTYPE html>
               <html>
               <head>
                   <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                   <style>
                       body { margin: 0; padding: 0; background-color: black; overflow: hidden; }
                       .container { position: relative; padding-bottom: 56.25%; height: 0; }
                       .container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
                   </style>
               </head>
               <body>
                   <div class="container">
                       <iframe src="https://www.youtube.com/embed/\(videoId)?autoplay=1&controls=\(showControls ? 1 : 0)&rel=0&modestbranding=1&playsinline=1" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
                   </div>
               </body>
               </html>
               """
        
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}
