//
//  PostsTableViewController.swift
//  SwiftDemo
//
//  Created by Dan Hassin on 8/21/14.
//  Copyright (c) 2014 Dan Hassin. All rights reserved.
//

import UIKit

class PostsTableViewController: UITableViewController {

    var posts:[Post]?
    
    func refresh() {
        Post.remoteAllAsync { array, error in
            if error != nil {
                AppDelegate.alertForError(error)
            } else {
                self.posts = array as? [Post]
                self.tableView.reloadData()
            }
        }
    }
    
    func addPost() {
        // When the + button is hit, display an InputViewController (this is the shared input view for both posts and responses)
        // It has an init method that accepts a completion block - this block of code will be executed when the user hits "save"

        let newPostVC = InputViewController(completionHandler: { author, content in
            let newPost = Post()
            newPost.author = author
            newPost.content = content
            
            newPost.remoteCreateAsync { error in
                if error != nil {
                    AppDelegate.alertForError(error)
                } else {
                    self.posts!.insert(newPost, atIndex:0)
                    self.tableView.reloadData()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        })
        
        newPostVC.header = "Post something to NSRails.com!"
        newPostVC.messagePlaceholder = "A comment about NSRails, a philosophical inquiry, or simply a \"hello world!\""
        
        self.presentViewController(UINavigationController(rootViewController: newPostVC), animated: true, completion: nil)
    }
    
    func deletePostAtIndexPath(indexPath:NSIndexPath) {
        let post = posts![indexPath.row]
        post.remoteDestroyAsync { error in
            if error != nil {
                AppDelegate.alertForError(error)
            } else {
                //remove from local array (we could `refresh` too)
                self.posts!.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refresh()
        
        self.title = "Posts"
        self.tableView.rowHeight = 60
        
        // Add refresh button
        let refresh = UIBarButtonItem(barButtonSystemItem:.Refresh, target:self, action:"refresh")
        self.navigationItem.leftBarButtonItem = refresh
        
        // Add the + button
        let plus = UIBarButtonItem(barButtonSystemItem:.Add, target:self, action:"addPost")
        self.navigationItem.rightBarButtonItem = plus
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return posts?.count ?? 0
    }

    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let CellIdentifier = "CellIdentifier"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell!
        if cell == nil {
            cell = UITableViewCell(style:.Subtitle, reuseIdentifier:CellIdentifier)
            cell.accessoryType = .DisclosureIndicator
        }

        let post = posts![indexPath.row]
        cell.textLabel.text = post.content
        cell.detailTextLabel.text = post.author

        return cell
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        return "Posts on http://NSRails.com!"
    }

    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let post = posts![indexPath.row]
        
        let rvc = ReponsesTableViewController(style: .Grouped)
        rvc.post = post
        self.navigationController.pushViewController(rvc, animated:true)
    }
    
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        deletePostAtIndexPath(indexPath)
    }
}
