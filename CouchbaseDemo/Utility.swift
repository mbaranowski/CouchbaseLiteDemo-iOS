//
//  Utility.swift
//  CouchbaseDemo
//
//  Created by MattBaranowski on 2/29/16.
//  Copyright © 2016 mattbaranowski. All rights reserved.
//

import Foundation

extension CBLView {
    // Just reorders the parameters to take advantage of Swift's trailing-block syntax.
    func setMapBlock(version: String, mapBlock: CBLMapBlock) -> Bool {
        return setMapBlock(mapBlock, version: version)
    }
}

extension NSDate {
    class func withJSONObject(jsonObj: AnyObject) -> NSDate? {
        return CBLJSON.dateWithJSONObject(jsonObj)
    }
}
