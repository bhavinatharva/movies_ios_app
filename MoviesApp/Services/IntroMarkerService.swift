//
//  IntroMarkerService.swift
//

import Foundation

protocol IntroMarkerServiceProtocol {
    func fetchIntroMarker(for streamId: String) async -> IntroMarker?
}

final class DummyIntroMarkerService: IntroMarkerServiceProtocol {
    static let shared = DummyIntroMarkerService()
    
    private init() {}
    
    func fetchIntroMarker(for streamId: String) async -> IntroMarker? {
        // Return nil as no dynamic intro markers are currently provided by the backend.
        // Once the API supports it, replace this implementation.
        return nil
    }
}
