import SwiftUI
import UIKit

struct AddPlaylistWizardView: View {
    @Environment(\.dismiss) var dismiss
    let onSuccess: () -> Void
    
    @State private var playlistType = 0 // 0: Xtream Codes, 1: M3U URL, 2: Local File
    @State private var name = ""
    @State private var urlString = ""
    @State private var username = ""
    @State private var password = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let playlistManager = PlaylistManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Playlist Type", selection: $playlistType) {
                        Text("Xtream Codes").tag(0)
                        Text("M3U URL").tag(1)
                        Text("Local File").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Details")) {
                    TextField("Playlist Name", text: $name)
                    
                    if playlistType == 0 {
                        TextField("Server URL (e.g. http://server:port)", text: $urlString)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: urlString) { _, newValue in
                                autoParseURL(newValue)
                            }
                        
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Password", text: $password)
                    } else if playlistType == 1 {
                        TextField("M3U URL", text: $urlString)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: urlString) { _, newValue in
                                autoParseURL(newValue)
                            }
                    } else {
                        Button(action: {
                            // File picker logic would go here
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Select File")
                            }
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Playlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task { await processPlaylist() }
                        }
                        .fontWeight(.bold)
                        .disabled(urlString.isEmpty && playlistType != 2)
                    }
                }
            }
            .disabled(isLoading)
        }
    }
    
    // MARK: - Logic
    
    private func autoParseURL(_ newValue: String) {
        let validation = IPTVValidator.validateIPTVSource(input: newValue)
        if validation.type == .xtreamCodes, let credentials = validation.credentials {
            self.playlistType = 0
            self.urlString = credentials.serverUrl
            self.username = credentials.username
            self.password = credentials.password
        }
    }
    
    private func processPlaylist() async {
        isLoading = true
        errorMessage = nil
        
        var targetUrl = urlString // We'll just pass the URL or build Xtream URL if needed
        if playlistType == 0 {
            let server = urlString.hasSuffix("/") ? String(urlString.dropLast()) : urlString
            targetUrl = "\(server)/get.php?username=\(username)&password=\(password)&type=m3u_plus&output=ts"
        }
        
        let validationResult = IPTVValidator.validateIPTVSource(input: targetUrl)
        
        guard validationResult.isValid, let sanitizedStr = validationResult.sanitizedUrl else {
            errorMessage = validationResult.errorMessage ?? "Invalid IPTV source. Please enter a valid URL."
            isLoading = false
            return
        }
        
        guard let url = URL(string: sanitizedStr) else {
            errorMessage = "Invalid URL format."
            isLoading = false
            return
        }
        
        do {
            var getRequest = URLRequest(url: url)
            getRequest.httpMethod = "GET"
            getRequest.setValue("bytes=0-200", forHTTPHeaderField: "Range")
            getRequest.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: getRequest)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 || httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    errorMessage = "Access denied or URL invalid (Status: \(httpResponse.statusCode))."
                    isLoading = false
                    return
                }
                if let content = String(data: data, encoding: .utf8)?.lowercased(), content.contains("<html") {
                    errorMessage = "Server returned an HTML page instead of playlist data."
                    isLoading = false
                    return
                }
            }
        } catch {
            errorMessage = "Connection Failed. Please check the URL and your internet connection."
            isLoading = false
            return
        }
        
        let finalName = name.isEmpty ? "My Playlist" : name
        playlistManager.addPlaylist(name: finalName, url: sanitizedStr)
        
        await IPTVDataManager.shared.refreshContent()
        
        // Success
        isLoading = false
        onSuccess()
        dismiss()
    }
}
