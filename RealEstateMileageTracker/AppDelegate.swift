//
//  AppDelegate.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import UIKit
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Check if app was launched due to location event
        if let _ = launchOptions?[.location] {
            print("🌙 App launched in background due to location update")
            // TripManager will handle location updates automatically
            // when initialized by the app
        }
        
        return true
    }
    
    // Force portrait mode only for all builds (dev and prod)
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
