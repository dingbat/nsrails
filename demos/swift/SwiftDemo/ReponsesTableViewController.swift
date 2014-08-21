//
//  ReponsesTableViewController.swift
//  SwiftDemo
//
//  Created by Dan Hassin on 8/21/14.
//  Copyright (c) 2014 Dan Hassin. All rights reserved.
//

import UIKit

class ReponsesTableViewController: UITableViewController {

    var post:Post!
    
    func reply() {
        // When the + button is hit, display an InputViewController (this is the shared input view for both posts and responses)
        // It has an init method that accepts a completion block - this block of code will be executed when the user hits "save"
        
        let newReplyVC = InputViewController(completionHandler: { author, content in
            let newResp = Response()
            newResp.author = author
            newResp.content = content
            newResp.post = self.post  //check out Response.swift for more detail on how this line is possible
            
            newResp.remoteCreateAsync() { error in
                if error != nil {
                    AppDelegate.alertForError(error)
                } else {
                    self.post.responses.append(newResp)
                    self.tableView.reloadData()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
            /*
            Instead of line 23 (the belongs_to trick), you could also add the new response to the post's "responses" array and then update it:
            
            post.responses.append(newResp)
            post.remoteUpdateAsync()...
            
            Doing this may be tempting since it'd already be in post's "responses" array, BUT: you'd have to take into account the Response validation failing (you'd then have to remove it from the array). Also, creating the Response rather than updating the Post will set newResp's remoteID, so we can do remote operations on it later!
            
            Of course, if you have CoreData enabled, this is all handled for you as soon as you set the response's post (the post's reponses array will automatically update), or vice versa (adding the response to the post's array will set the response's post property)
            */
            })
        
        newReplyVC.header = "Write your response to \(post.author)"
        newReplyVC.messagePlaceholder = "Your response"
        
        self.presentViewController(UINavigationController(rootViewController: newReplyVC), animated: true, completion: nil)
    }
    
    func deleteResponseAtIndexPath(indexPath:NSIndexPath) {
        let response = post.responses[indexPath.row]
        
        response.remoteDestroyAsync { error in
            if error != nil {
                AppDelegate.alertForError(error)
            } else {
                self.post.responses.removeAtIndex(indexPath.row) // Remember to delete the object from our local array too
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                
                if (self.post.responses.count == 0) {
                    self.tableView.reloadSections(NSIndexSet(index:0), withRowAnimation:.Automatic)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Posts"
        self.tableView.rowHeight = 60
        
        // Add reply button
        let reply = UIBarButtonItem(barButtonSystemItem:.Reply, target:self, action:"reply")
        self.navigationItem.rightBarButtonItem = reply
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
        return post.responses.count
    }

    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let CellIdentifier = "CellIdentifier"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell!
        if cell == nil {
            cell = UITableViewCell(style:.Subtitle, reuseIdentifier:CellIdentifier)
            cell.selectionStyle = .None
        }
        
        let response = post.responses[indexPath.row]
        cell.textLabel.text = response.content
        cell.detailTextLabel.text = response.author

        return cell
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        return "“\(post.content)”"
    }
    
    override func tableView(tableView: UITableView!, titleForFooterInSection section: Int) -> String! {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        
        var footer = "(Posted on \(formatter.stringFromDate(post.createdAt)))"
        if (post.responses.count == 0) {
            footer = "There are no responses to this post.\nSay something!\n\n"+footer
        }
        return footer
    }
    
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        deleteResponseAtIndexPath(indexPath)
    }
}
