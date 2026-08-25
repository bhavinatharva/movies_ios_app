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
    @State private var importTask: Task<Void, Never>?
    
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
                
                // Error message moved to the overlay as requested
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
                            importTask = Task { await processPlaylist() }
                        }
                        .fontWeight(.bold)
                        .disabled(urlString.isEmpty && playlistType != 2)
                    }
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 20) {
                            if let error = errorMessage {
                                // Error State
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text("Import Failed")
                                    .font(.title2).bold()
                                    .foregroundColor(.white)
                                Text(error)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 20) {
                                    Button("Retry") {
                                        importTask = Task { await processPlaylist() }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    
                                    Button("Cancel") {
                                        isLoading = false
                                        errorMessage = nil
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.white)
                                }
                            } else {
                                // Loading State
                                if let progress = IPTVDataManager.shared.importProgress {
                                    WaterWaveProgressView(progress: progress, waveHeight: 0.05, waveFrequency: 1.5, waveSpeed: 2.0, color: .accentColor)
                                        .frame(width: 150, height: 150)
                                } else {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.accentColor)
                                }
                                Text("Processing Playlist...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Button("Cancel") {
                                    importTask?.cancel()
                                    IPTVDataManager.shared.cancelImport()
                                    isLoading = false
                                }
                                .buttonStyle(.bordered)
                                .tint(.white)
                                .padding(.top, 10)
                            }
                        }
                    }
                }
            }
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
        guard !isLoading || errorMessage != nil else { return } // Prevent duplicates, allow retry
        isLoading = true
        errorMessage = nil
        IPTVDataManager.shared.importProgress = 0.0
        
        defer {
            // Always reset importProgress when the wizard exits (success, failure, or cancel).
            IPTVDataManager.shared.importProgress = nil
        }
        
        var targetUrl = urlString // We'll just pass the URL or build Xtream URL if needed
        if playlistType == 0 {
            var cleanUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanUrl.lowercased().hasPrefix("http://") && !cleanUrl.lowercased().hasPrefix("https://") {
                cleanUrl = "http://" + cleanUrl
            }
            
            if let url = URL(string: cleanUrl), let scheme = url.scheme, let host = url.host {
                let portStr = url.port != nil ? ":\(url.port!)" : ""
                let server = "\(scheme)://\(host)\(portStr)"
                
                if var components = URLComponents(string: "\(server)/player_api.php") {
                    components.queryItems = [
                        URLQueryItem(name: "username", value: username.trimmingCharacters(in: .whitespacesAndNewlines)),
                        URLQueryItem(name: "password", value: password.trimmingCharacters(in: .whitespacesAndNewlines))
                    ]
                    if let finalUrlString = components.url?.absoluteString {
                        targetUrl = finalUrlString
                    }
                }
            } else {
                // Fallback if parsing fails
                let server = urlString.hasSuffix("/") ? String(urlString.dropLast()) : urlString
                targetUrl = "\(server)/player_api.php?username=\(username)&password=\(password)"
            }
        }
        
        let validationResult = IPTVValidator.validateIPTVSource(input: targetUrl)
        
        guard validationResult.isValid, let sanitizedStr = validationResult.sanitizedUrl else {
            errorMessage = validationResult.errorMessage ?? "Invalid IPTV source. Please enter a valid URL."
            return
        }
        
        guard let url = URL(string: sanitizedStr) else {
            errorMessage = "Invalid URL format."
            return
        }
        
        do {
            var getRequest = URLRequest(url: url)
            getRequest.httpMethod = "GET"
            getRequest.setValue("VLC/3.0.11 LibVLC/3.0.11", forHTTPHeaderField: "User-Agent")
            getRequest.timeoutInterval = 15
            
            if playlistType == 0 {
                // Xtream Codes validation (tiny JSON payload)
                let (data, response) = try await URLSession.shared.data(for: getRequest)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 404 || httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        errorMessage = "Access denied or URL invalid (Status: \(httpResponse.statusCode))."
                        return
                    }
                    if let mimeType = httpResponse.mimeType, mimeType.contains("text/html") {
                        errorMessage = "Server returned an HTML page instead of playlist data."
                        return
                    }
                }
                if let content = String(data: data, encoding: .utf8)?.lowercased(), content.contains("<html") {
                    errorMessage = "Server returned an HTML page instead of playlist data."
                    return
                }
            } else {
                // M3U validation (prevent downloading massive files)
                let (asyncBytes, response) = try await URLSession.shared.bytes(for: getRequest)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 404 || httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        errorMessage = "Access denied or URL invalid (Status: \(httpResponse.statusCode))."
                        return
                    }
                    if let mimeType = httpResponse.mimeType, mimeType.contains("text/html") {
                        errorMessage = "Server returned an HTML page instead of playlist data."
                        return
                    }
                }
                
                var initialData = Data()
                var iterator = asyncBytes.makeAsyncIterator()
                // Read up to 200 bytes, but gracefully handle end of stream
                for _ in 0..<200 {
                    if let byte = try await iterator.next() {
                        initialData.append(byte)
                    } else {
                        break
                    }
                }
                
                if let content = String(data: initialData, encoding: .utf8)?.lowercased(), content.contains("<html") {
                    errorMessage = "Server returned an HTML page instead of playlist data."
                    return
                }
            }
        } catch is CancellationError {
            // Task cancelled
            return
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                // Task cancelled
                return
            }
            errorMessage = "Connection Failed: \(error.localizedDescription)"
            return
        }
        
        let finalName = name.isEmpty ? "My Playlist" : name
        if Task.isCancelled { return }
        
        let newPlaylist = playlistManager.addPlaylist(name: finalName, url: sanitizedStr)
        playlistManager.setDefault(newPlaylist)
        
        await IPTVDataManager.shared.refreshContent(clearFirst: true)
        
        if Task.isCancelled {
            // Cleanup on cancel if needed, though refreshContent might have run
            return
        }
        
        // Success
        isLoading = false
        onSuccess()
        dismiss()
    }
}
