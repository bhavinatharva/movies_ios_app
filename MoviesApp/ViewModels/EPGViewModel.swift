import SwiftUI
import Combine

@MainActor
class EPGViewModel: ObservableObject {
    @Published var channels: [IPTVChannel] = []
    @Published var programs: [String: [EPGProgram]] = [:] // key: channelId
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    
    // Time grid variables
    @Published var currentTime: Date = Date()
    @Published var startHour: Date = Date()
    @Published var hoursToShow = 6
    
    func loadEPG() async {
        self.isLoading = true
        self.errorMessage = nil
        
        let allChannels = IPTVLocalDatabase.shared.fetchChannels()
        let liveChannels = allChannels.filter { $0.mediaType == .liveTV }
        
        self.channels = liveChannels
        
        // Get Credentials
        guard let activeUrl = UserDefaults.standard.string(forKey: "active_playlist_url") else {
            self.errorMessage = "No active playlist found."
            self.isLoading = false
            return
        }
        
        let validation = IPTVURLValidator.validateIPTVSource(input: activeUrl)
        if let creds = validation.credentials {
            do {
                let epgData = try await XtreamProvider.shared.fetchEPG(creds: creds)
                let parsedPrograms = try await EPGService.shared.parseXMLTV(data: epgData)
                
                // Group by channel id
                var dict: [String: [EPGProgram]] = [:]
                for p in parsedPrograms {
                    dict[p.channelId, default: []].append(p)
                }
                
                // Sort programs by time
                for key in dict.keys {
                    dict[key]?.sort(by: { $0.start < $1.start })
                }
                
                self.programs = dict
            } catch {
                self.errorMessage = "Failed to load TV Guide: \(error.localizedDescription)"
            }
        }
        
        // Round startHour down to the nearest hour
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day, .hour], from: Date())
        comps.minute = 0
        comps.second = 0
        self.startHour = calendar.date(from: comps) ?? Date()
        
        self.isLoading = false
    }
}
