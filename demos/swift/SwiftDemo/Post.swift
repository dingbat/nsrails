//
//  Post.swift
//  SwiftDemo
//
//  Created by Dan Hassin on 8/21/14.
//  Copyright (c) 2014 Dan Hassin. All rights reserved.
//

import UIKit

@objc(Post) class Post: NSRRemoteObject {
    var content:String!
    var author:String!
    var responses:[Response]!
    var createdAt:NSDate!
    
    override func nestedClassForProperty(property: String!) -> AnyClass! {
        if property == "responses" {
            return Response.self
        }
        
        return super.nestedClassForProperty(property)
    }
}
