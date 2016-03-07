//
//  DataService.swift
//  CouchbaseDemo
//
//  Created by MattBaranowski on 2/29/16.
//  Copyright © 2016 mattbaranowski. All rights reserved.
//

import Foundation


class DataService : NSObject {
    let database: CBLDatabase!
    
    let serverDBURL : NSURL?
    private var push: CBLReplication? = nil
    private var pull: CBLReplication? = nil
    private var syncError: NSError?

    var progressBar : UIProgressView? = nil
    
    init?(databaseName: String, serverDBURL: NSURL?) {
        do {
            self.database = try CBLManager.sharedInstance().databaseNamed(databaseName)
        } catch {
            self.serverDBURL = nil
            self.database = nil
            super.init()
            return nil
        }

        self.serverDBURL = serverDBURL
        super.init()
        
        CBLManager.sharedInstance().excludedFromBackup = true
        
        if let url = self.serverDBURL {
            self.push = self.setupReplication(database.createPushReplication(url))
            self.pull = self.setupReplication(database.createPullReplication(url))
            self.push?.start()
            self.pull?.start()
            
            if self.push?.status == .Offline {
                print("Warning: push replication to \(url) is offline!")
            }
        }
    }
    
    func setupReplication(replication: CBLReplication!) -> CBLReplication! {
        if replication != nil {
            replication.continuous = true
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: "replicationProgress:",
                name: kCBLReplicationChangeNotification,
                object: replication)
        }
        return replication
    }
    
    func replicationProgress(n: NSNotification) {
        
        if  let progressBar = self.progressBar,
            let pull = self.pull,
            let push = self.push {

            if (pull.status == CBLReplicationStatus.Active || push.status == CBLReplicationStatus.Active) {
                // Sync is active -- aggregate the progress of both replications and compute a fraction:
                let completed = pull.completedChangesCount + push.completedChangesCount
                let total = pull.changesCount + push.changesCount
                NSLog("SYNC progress: %u / %u", completed, total)
                // Update the progress bar, avoiding divide-by-zero exceptions:
                progressBar.progress = Float(completed) / Float(max(total, 1))
                progressBar.hidden = false
            } else {
                // Sync is idle -- hide the progress bar:
                progressBar.hidden = true
            }
            
            // Check for any change in error status and display new errors:
            let error = pull.lastError ?? push.lastError
            if (error != syncError) {
                syncError = error
                if error != nil {
                    DataService.showAlert("Error syncing", forError: error)
                }
            }
        }
    }
    
   class func showAlert(var message: String, forError error: NSError?) {
        if error != nil {
            message = "\(message)\n\n\((error?.localizedDescription)!)"
        }
        NSLog("ALERT: %@ (error=%@)", message, (error ?? ""))
        
        // TODO replace with UIAlertViewController
        let alert = UIAlertView(
            title: "Error",
            message: message,
            delegate: nil,
            cancelButtonTitle: "Ok")
        alert.show()
    }
}