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
    let showControls : Bool
    let youtubeBaseUrl = ApiConfig.shared?.youtubeBaseUrl
    
    func makeUIView(context : Context ) -> some UIView {
        webview.configuration.allowsInlineMediaPlayback = true
        webview.configuration.mediaTypesRequiringUserActionForPlayback = []
        webview.scrollView.isScrollEnabled = false
        webview.isOpaque = false
        webview.backgroundColor = .black
        return webview
    }
    
    func updateUIView(_ uiView :UIViewType, context :Context)  {
        guard let baseYoutubeURL = youtubeBaseUrl,
              let baseURL = URL(string: baseYoutubeURL)else {return}
        let fullURL = baseURL.appending(path: videoId)
        print("fullURL \(fullURL)")
        let controlsParam = showControls ? "1" : "0"
        
        let htmlString = """
               <!DOCTYPE html>
               <html>
               <head>
                   <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                   <style>
                       body {
                           margin: 0;
                           padding: 0;
                           background-color: black;
                           display: flex;
                           justify-content: center;
                           align-items: center;
                           height: 100vh;
                       }
                       .container {
                           width: 100%;
                           height: 100%;
                       }
                       iframe {
                           width: 100%;
                           height: 100%;
                           border: none;
                       }
                   </style>
               </head>
               <body>
                   <div class="container">
                       <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/-VC3hIEL7eQ?si=B_FEdNEJTSY0ADf2&amp;start=8240" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                   </div>
               </body>
               </html>
               """
        
        webview.loadHTMLString(htmlString, baseURL: nil)
    }
}
