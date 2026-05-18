//
//  LoginView.swift
//  MoviesApp
//
//  Created by Antigravity on 15/05/26.
//

import SwiftUI

struct LoginView: View {
    @State private var serverUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let authManager = AuthManager.shared
    private let iptvService = IPTVService.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "tv.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("IPTV Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    TextField("Server URL (http://...)", text: $serverUrl)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: handleLogin) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 5)
                        }
                        Text("Sign In")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .disabled(isLoading || serverUrl.isEmpty || username.isEmpty || password.isEmpty)
                
                Spacer()
            }
        }
    }
    
    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Sanitize and extract base URL (scheme + host + port)
            var cleanUrl = serverUrl.replacingOccurrences(of: " ", with: "")
            cleanUrl = cleanUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleanUrl.lowercased().hasPrefix("http://") && !cleanUrl.lowercased().hasPrefix("https://") {
                cleanUrl = "http://" + cleanUrl
            }
            
            let parts = cleanUrl.components(separatedBy: "://")
            if parts.count >= 2 {
                let scheme = parts[0]
                var rest = parts[1]
                while rest.hasPrefix("/") {
                    rest.removeFirst()
                }
                cleanUrl = "\(scheme)://\(rest)"
            }
            
            if let url = URL(string: cleanUrl), let scheme = url.scheme, let host = url.host {
                var baseUrl = "\(scheme)://\(host)"
                if let port = url.port {
                    baseUrl += ":\(port)"
                }
                cleanUrl = baseUrl
            }
            
            let creds = XtreamCredentials(serverUrl: cleanUrl, username: username.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            
            do {
                let success = try await iptvService.loginXtream(creds: creds)
                if success {
                    await MainActor.run {
                        authManager.saveCredentials(creds)
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Invalid credentials or unauthorized"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Connection error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
