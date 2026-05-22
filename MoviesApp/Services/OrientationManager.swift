import Foundation
import UIKit
import SwiftUI
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
    
    // Global variable to keep track of allowed orientations
    static var orientationLock = UIInterfaceOrientationMask.allButUpsideDown
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask, rotateTo: UIInterfaceOrientation? = nil) {
        AppDelegate.orientationLock = orientation
        
        if let targetOrientation = rotateTo {
            if #available(iOS 16.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            } else {
                UIDevice.current.setValue(targetOrientation.rawValue, forKey: "orientation")
            }
        }
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
