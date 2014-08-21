//
//  Response.swift
//  SwiftDemo
//
//  Created by Dan Hassin on 8/21/14.
//  Copyright (c) 2014 Dan Hassin. All rights reserved.
//

import UIKit

@objc(Response) class Response: NSRRemoteObject {
    var post:Post!
    var content:String!
    var author:String!
    
    override func shouldOnlySendIDKeyForNestedObjectProperty(property: String!) -> Bool {
        return property == "post"
    }
    
    /*
    ==================
    Note:
    ==================
    
    Overriding shouldOnlySendIDKeyForNestedObjectProperty: above is necessary for any relationships that are 'belongs-to' on Rails.
    
    * Returning NO means that when sending a Response, 'post' will be sent as a dictionary with remote key 'post_attributes'.
    
    * Returning YES means that when sending a Response, only the remoteID from 'post' will be sent, with the remote key 'post_id'
    
    
    This means that you don't need to define a postID attribute in your Response class, assign it a real Post object, and still have Rails be chill when receiving it! (Rails gets angry if you send it _attributes for a belongs-to relation.)
    
    Of course, this is only relevant for belongs-to since you'd typically *want* the "_attributes" key in most cases.
    */

}
