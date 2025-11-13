//
//  Constants.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import Foundation

struct Constants {
    struct ImageConstants {
        static let tabHome = "house"
        static let tabUpcoming = "play.circle"
        static let tabSearch = "magnifyingglass"
        static let tabDownloads = "arrow.down.to.line"
        
        static let movie = "movieclapper"
        static let tv = "tv"
        static let trash = "trash"
        
        static let heroBannerMovie = "https://i.ebayimg.com/images/g/55oAAOSw9PlhoDWJ/s-l1200.jpg"
        static let image1 = "https://www.tallengestore.com/cdn/shop/products/Joker_-_Joaquin_Phoenix_-_Hollywood_Action_Movie_Poster_4d1b0644-dd78-42f8-996a-5d0c5bdc21b5.jpg?v=1573629455"
        static let image2 = "https://www.indiewire.com/wp-content/uploads/2019/12/us-1.jpg?w=758"
        static let image3 = "https://images-cdn.ubuy.co.in/68b1b650d9f8d3e89e042c52-star-wars-rogue-one-movie-poster.jpg"
        static let image4 = "https://i.etsystatic.com/37166133/r/il/60f034/4087791906/il_570xN.4087791906_jcbj.jpg"
        
        static let posterPathStart = "https://image.tmdb.org/t/p/w500"
        
        static func addPosterPth (to titles: inout[TrendingModel]){
            for index in titles.indices {
                if let path = titles[index].posterPath {
                    titles[index].posterPath = posterPathStart + path
                }
            }
        }
    }
    
    struct StringConstants {
        static let tabHome = "Home"
        static let tabUpcoming = "Upcoming"
        static let tabSearch = "Search"
        static let tabDownloads="Downloads"
        
        static let btnPlay = "Play"
        static let btnDownload = "Download"
        
        static let trendingMovies = "Trending Movies"
        static let trendingTvShows = "Trending TV Shows"
        static let topRatedMovies = "Top Rated Movies"
        static let topRatedTvShows = "Top Rates TV Shows"
     
        static let movieSearch = "Movie Search"
        static let tvSearch = "TV Search"
        
        static let search = "Search ..."
        
    }
}
