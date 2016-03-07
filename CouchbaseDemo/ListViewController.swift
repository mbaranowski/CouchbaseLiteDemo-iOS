//
//  ViewController.swift
//  CouchbaseDemo
//
//  Created by MattBaranowski on 2/29/16.
//  Copyright © 2016 mattbaranowski. All rights reserved.
//

import UIKit

class DeliveryTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel : UILabel!
    @IBOutlet var streetAddressLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
}

class ListViewController: UITableViewController {

    var context : AppContext!
    var controller : ListController!
    
    static func build(context : AppContext) -> ListViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ListViewController") as! ListViewController
        vc.context = context
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.controller = ListController(context: self.context, tableView: self.tableView)
        
        
        self.tableView.delegate = self
        self.tableView.separatorStyle = .None
        
        // Initialize the "Clean" button:
        let deleteButton = UIBarButtonItem(
            title:  "Clear",
            style:  .Plain,
            target: self,
            action: "deleteCompletedItems")
        self.navigationItem.leftBarButtonItem = deleteButton
        
        let addButton = UIBarButtonItem(
            title:  "Add",
            style:  .Plain,
            target: self,
            action: "addNewItem")
        self.navigationItem.rightBarButtonItem = addButton
        
        // Initialize the sync progress bar:
        let title = UILabel()
        title.text = "DSS Couchbase Prototype"
        title.sizeToFit()
        
        let progressBar = UIProgressView(progressViewStyle: .Bar)
        var frame = progressBar.frame
        frame.size.width = self.view.frame.size.width / 4
        progressBar.frame = frame

        let stackView = UIStackView(arrangedSubviews: [title, progressBar])
        stackView.axis = .Vertical
        stackView.distribution = .FillProportionally
        stackView.alignment = .Center
        
        stackView.frame = CGRect(x: 0, y: 0,
            width: self.navigationController?.navigationBar.frame.size.width ?? 200,
            height: self.navigationController?.navigationBar.frame.size.height ?? 44)
        self.navigationItem.titleView = stackView
        self.context.dataService.progressBar = progressBar
    }

    func couchTableSource(source: CBLUITableSource, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("DeliveryTableViewCell", forIndexPath: indexPath) as! DeliveryTableViewCell
        
        if let doc = self.controller.documentAtIndex(indexPath.row) {
            cell.selectionStyle = .Gray
            cell.nameLabel.text = doc["name"] as? String ?? ""
            cell.streetAddressLabel.text = doc["streetAddress"] as? String ?? ""
            cell.addressLabel.text = doc["address"] as? String ?? ""
            cell.statusLabel.text = doc["status"] as? String ?? ""
        }
        
        return cell
    }
    
    func addDocumentAlertDialog() -> UIAlertController {
        return self.editDocumentAlertDialog(nil)
    }
    
    func editDocumentAlertDialog(doc : CBLDocument?) -> UIAlertController {
        let alert = UIAlertController(title: "Edit Item", message: "Please edit field", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField : UITextField) -> Void in
            textField.placeholder = "Name"
            textField.text = doc?["name"] as? String
        }
        alert.addTextFieldWithConfigurationHandler { (textField : UITextField) -> Void in
            textField.placeholder = "Street Address"
            textField.text = doc?["streetAddress"] as? String
        }
        alert.addTextFieldWithConfigurationHandler { (textField : UITextField) -> Void in
            textField.placeholder = "Address"
            textField.text = doc?["address"] as? String
        }
        alert.addTextFieldWithConfigurationHandler { (textField : UITextField) -> Void in
            textField.placeholder = "Status"
            textField.text = doc?["status"] as? String
        }
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) { _ -> Void in
            if  let name = alert.textFields?[0].text,
                let street = alert.textFields?[1].text,
                let address = alert.textFields?[2].text,
                let status = alert.textFields?[3].text
            {
                do {
                    if let doc = doc {
                        try doc.update({ (newDoc : CBLUnsavedRevision) -> Bool in
                            newDoc["name"] = name
                            newDoc["streetAddress"] = street
                            newDoc["address"] = address
                            newDoc["status"] = status
                            return true
                        })
                    } else {
                        try self.controller.createNewItem(name, streetAddress: street, address: address, status: status)
                    }
                } catch {
                    print("error \(error)")
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { _ -> Void in
            print("cancel action")
        }))

        return alert
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let doc = self.controller.documentAtIndex(indexPath.row) else {
            return
        }

        let alert = editDocumentAlertDialog(doc)
        
        self.presentViewController(alert, animated: true, completion: nil)
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    func addNewItem() {
        let alert = addDocumentAlertDialog()
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func deleteCompletedItems() {
        
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let doc = self.controller.documentAtIndex(indexPath.row) {
                do {
                    try self.controller.deleteDocuments([doc])
                } catch {
                    print("failed to delete doc \(error)")
                }
            }
        }
    }
    
}

