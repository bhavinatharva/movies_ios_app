//
//  SettingsView.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("iptv_url") private var iptvUrl = "https://iptv-org.github.io/iptv/index.m3u"
    @State private var tempUrl = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IPTV Playlist URL")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter .m3u URL", text: $tempUrl)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        iptvUrl = tempUrl
                        dismiss()
                    }) {
                        Text("Save Playlist")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            tempUrl = iptvUrl
        }
    }
}
