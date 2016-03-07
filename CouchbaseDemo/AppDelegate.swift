//
//  AppDelegate.swift
//  CouchbaseDemo
//
//  Created by MattBaranowski on 2/29/16.
//  Copyright © 2016 mattbaranowski. All rights reserved.
//

import UIKit


private let kDatabaseName = "grocery-sync"
private let kServerDbURL = NSURL(string: "http://localhost:4984/sync_gateway/")!


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var context : AppContext!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let dataService = DataService(databaseName: kDatabaseName, serverDBURL: kServerDbURL)
        if dataService == nil {
            DataService.showAlert("Failed to open main database.", forError: nil)
            return false
        }
        
        self.context = AppContext(dataService: dataService)

        let vc = ListViewController.build(self.context)
        let navController = UINavigationController(rootViewController: vc)
        
        self.window!.rootViewController = navController
        self.window!.makeKeyAndVisible()
        return true
    }

}

