//
//  AuthManager.swift

//
//  Created by Antigravity on 15/05/26.
//

import Foundation
import SwiftUI

@Observable
class AuthManager {
    static let shared = AuthManager()
    
    var credentials: XtreamCredentials?
    var isLoggedIn: Bool = false
    
    private let credsKey = "xtream_credentials"
    
    private init() {
        loadCredentials()
    }
    
    func saveCredentials(_ creds: XtreamCredentials) {
        if let encoded = try? JSONEncoder().encode(creds) {
            UserDefaults.standard.set(encoded, forKey: credsKey)
            self.credentials = creds
            self.isLoggedIn = true
        }
    }
    
    func loadCredentials() {
        if let data = UserDefaults.standard.data(forKey: credsKey),
           let creds = try? JSONDecoder().decode(XtreamCredentials.self, from: data) {
            self.credentials = creds
            self.isLoggedIn = true
        } else {
            self.credentials = nil
            self.isLoggedIn = false
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: credsKey)
        self.credentials = nil
        self.isLoggedIn = false
    }
}
