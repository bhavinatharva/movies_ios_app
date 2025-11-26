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
    
    
    func getActors(searchPhase : String) async {
        actorStatus=ApiFetchStatus.loading
        
        if actorsData.isEmpty {
            do{
                print("searchPhase",searchPhase)
                if searchPhase.isEmpty {
                    actorsData = try await apiService.fetchActors(searchBy: nil)
                }else {
                    actorsData = try await apiService.fetchActors(searchBy: searchPhase)
                }
            
                actorStatus = ApiFetchStatus.success
            }
            catch {
                actorStatus=ApiFetchStatus.error(underlyingError: error)
            }
        }else {
            actorStatus = ApiFetchStatus.success
        }
    }
    
}
