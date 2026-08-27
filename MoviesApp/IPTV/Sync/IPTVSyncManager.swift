//
//  IPTVSyncManager.swift
//
//  Created by Antigravity on 27/08/26.
//

import Foundation
import Combine

enum IPTVSyncStatus: Equatable {
    case idle
    case syncing(progress: Double)
    case success
    case error(message: String)
}

@MainActor
@Observable
class IPTVSyncManager {
    static let shared = IPTVSyncManager()
    
    // Status mapped by Playlist ID to support multiple playlists
    var syncStatuses: [String: IPTVSyncStatus] = [:]
    var activeSyncTasks: [String: Task<Void, Never>] = [:]
    
    private init() {}
    
    func status(for playlistId: String) -> IPTVSyncStatus {
        return syncStatuses[playlistId] ?? .idle
    }
    
    func startSync(playlist: Playlist) {
        let playlistId = playlist.id
        
        // Prevent duplicate syncs
        if let currentStatus = syncStatuses[playlistId] {
            if case .syncing(_) = currentStatus {
                return
            }
        }
        
        // Cancel any existing task just in case
        activeSyncTasks[playlistId]?.cancel()
        
        syncStatuses[playlistId] = .syncing(progress: 0.0)
        
        let task = Task {
            do {
                let fetcher = IPTVDataFetcher()
                try await fetcher.fetchAndSave(playlist: playlist) { [weak self] progress in
                    guard let self = self else { return }
                    Task { @MainActor in
                        if case .syncing = self.syncStatuses[playlistId] {
                            self.syncStatuses[playlistId] = .syncing(progress: progress)
                        }
                    }
                }
                
                if Task.isCancelled {
                    self.syncStatuses[playlistId] = .idle
                    return
                }
                
                self.syncStatuses[playlistId] = .success
                
            } catch is CancellationError {
                self.syncStatuses[playlistId] = .idle
            } catch {
                self.syncStatuses[playlistId] = .error(message: error.localizedDescription)
            }
            
            self.activeSyncTasks[playlistId] = nil
        }
        
        activeSyncTasks[playlistId] = task
    }
    
    func cancelSync(playlistId: String) {
        activeSyncTasks[playlistId]?.cancel()
        activeSyncTasks[playlistId] = nil
        syncStatuses[playlistId] = .idle
    }
}
