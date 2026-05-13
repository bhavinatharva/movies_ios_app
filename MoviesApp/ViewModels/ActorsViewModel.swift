//

//  UpcomingViewModel.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

@Observable
class ActorsViewModel {
    private(set) var actorStatus = ApiFetchStatus.notstarted
    
    private let apiService = ApiServices()
    var actorsData: [ActorModel] = []
    var popularActors: [ActorModel] = []
    var trendingActors: [ActorModel] = []
    
    
    func getActors(searchPhase : String) async {
        actorStatus=ApiFetchStatus.loading
        
        do{
            if searchPhase.isEmpty {
                actorsData = try await apiService.fetchActors(searchBy: nil)
                // Simple partitioning for UI variety
                popularActors = Array(actorsData.prefix(10))
                trendingActors = Array(actorsData.suffix(max(0, actorsData.count - 10)))
            }else {
                actorsData = try await apiService.fetchActors(searchBy: searchPhase)
                popularActors = actorsData
                trendingActors = []
            }
        
            actorStatus = ApiFetchStatus.success
        }
        catch {
            actorStatus=ApiFetchStatus.error(underlyingError: error)
        }
    }
    
}
