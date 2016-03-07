
//
//  LostController.swift
//  CouchbaseDemo
//
//  Created by MattBaranowski on 2/29/16.
//  Copyright © 2016 mattbaranowski. All rights reserved.
//

import Foundation

class ListController : NSObject {
    var context : AppContext!
    
    let dataSource = CBLUITableSource()
    
    var db : CBLDatabase {
        return self.context.dataService.database
    }
    
    var checkedDocuments :[CBLDocument] {
        // (If there were a whole lot of documents, this would be more efficient with a custom query.)
        let rows = self.dataSource.rows!
        return rows.filter {
            guard let value = $0.value as? NSDictionary,
                let check = value["check"] as? Bool else {
                    return false
            }
            return check
            }.map { $0.document! }
    }
    
    init(context : AppContext, tableView: UITableView) {
        self.context = context
        super.init()
        
        // Define a view with a map function that indexes to-do items by creation date:
        db.viewNamed("byDate").setMapBlock("2") {
            (doc, emit) in
            if let date = doc["created_at"] as? String {
                emit(date, doc)
            }
        }
        
        // ...and a validation function requiring parseable dates:
        db.setValidationNamed("created_at") {
            (newRevision, context) in
            if !newRevision.isDeletion,
                let date = newRevision.properties?["created_at"] as? String
                where NSDate.withJSONObject(date) == nil {
                    context.rejectWithMessage("invalid date \(date)")
            }
        }
        
        // Create a query sorted by descending date, i.e. newest items first:
        let query = db.viewNamed("byDate").createQuery().asLiveQuery()
        query.descending = true
        
        // Plug the query into the CBLUITableSource, which will use it to drive the table view.
        // (The CBLUITableSource uses KVO to observe the query's .rows property.)
        self.dataSource.tableView = tableView
        tableView.dataSource = self.dataSource
        self.dataSource.query = query
        self.dataSource.labelProperty = nil    // Document property to display in the cell label
    }
    
    
    func createNewItem(name : String, streetAddress : String, address : String, status : String) throws {
        let properties: [String : AnyObject] = [
            "name": name,
            "streetAddress": streetAddress,
            "address": address,
            "status": status,
            "check": false,
            "created_at": CBLJSON.JSONObjectWithDate(NSDate())]
        
        // Save the document:
        let doc = db.createDocument()
        try doc.putProperties(properties)
    }
    
    func documentAtIndex(idx : Int) -> CBLDocument? {
        if let row = self.dataSource.rowAtIndex(UInt(idx)),
            let doc = row.document {
                return doc
        }
        
        return nil
    }
    
    func deleteDocuments(docs : [CBLDocument]) throws {
        try dataSource.deleteDocuments(docs)
    }
}