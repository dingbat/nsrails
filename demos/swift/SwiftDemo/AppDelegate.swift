//
//  AppDelegate.swift
//  SwiftDemo
//
//  Created by Dan Hassin on 8/21/14.
//  Copyright (c) 2014 Dan Hassin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var navController: UINavigationController?


    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        
        NSRConfig.defaultConfig().rootURL = NSURL(string:"http://nsrails.com")
        NSRConfig.defaultConfig().basicAuthUsername = "NSRails"
        NSRConfig.defaultConfig().basicAuthPassword = "iphone"
        NSRConfig.defaultConfig().configureToRailsVersion(NSRRailsVersion.Version3)
        
        window = UIWindow(frame:UIScreen.mainScreen().bounds)
        
        let posts = PostsTableViewController(style:.Grouped)
        navController = UINavigationController(rootViewController:posts)
        
        window!.rootViewController = navController
        window!.makeKeyAndVisible()

        return true
    }

    class func alertForError(error:NSError) {
        var errorString = ""
        
        if let validationErrors = error.userInfo![NSRErrorResponseBodyKey] as AnyObject! as? [NSString:[NSString]]? {
            // Iterate through each failed property (keys) and the reason it failed
            for (failedProperty, reasons) in validationErrors! {
                for reason in reasons {
                    errorString += "\(failedProperty.capitalizedString) \(reason). " //=> "Name can't be blank."
                }
            }
        } else if (error.domain == NSRRemoteErrorDomain) {
            errorString = "Something went wrong: \(error.localizedDescription)"
        } else {
            errorString = "There was an error connecting to the server."
        }
        
        UIAlertView(title: "Error", message: errorString, delegate: nil, cancelButtonTitle: "OK").show()
    }
}

