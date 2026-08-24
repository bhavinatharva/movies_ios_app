//
//  AdultContentModal.swift

//
//  Created by Antigravity on 21/05/26.
//

import SwiftUI

struct AdultConsentModal: View {
    var dataManager: IPTVDataManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(.red)
                .padding(.top, 16)
            
            VStack(spacing: 8) {
                Text("18+ Content Detected")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("This playlist contains adult content. Would you like to enable access to these categories?")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button {
                    dataManager.handleAdultConsent(consented: true)
                } label: {
                    Text("Enable Adult Content")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(12)
                }
                
                Button {
                    dataManager.handleAdultConsent(consented: false)
                } label: {
                    Text("Keep Disabled")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}
