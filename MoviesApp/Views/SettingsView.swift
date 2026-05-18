//
//  SettingsView.swift
//  MoviesApp
//

import SwiftUI

struct SettingsView: View {
    @State private var authManager = AuthManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    Section(header: Text("Account Details").foregroundColor(.gray)) {
                        if let creds = authManager.credentials {
                            HStack {
                                Text("Server")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(creds.serverUrl)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            .listRowBackground(Color.gray.opacity(0.1))
                            
                            HStack {
                                Text("Username")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(creds.username)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            .listRowBackground(Color.gray.opacity(0.1))
                        }
                    }
                    
                    Section {
                        Button(action: {
                            authManager.logout()
                        }) {
                            Text("Logout")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }
                    
                    Section(footer: Text("App Version 1.0").frame(maxWidth: .infinity, alignment: .center)) {
                        EmptyView()
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Constants.StringConstants.tabSettings)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
