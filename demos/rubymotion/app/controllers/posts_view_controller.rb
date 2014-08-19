class PostsViewController < UITableViewController
  def add
    # When the + button is hit, display an InputViewController (this is the shared input view for both posts and responses)
    # It has an init method that accepts a completion block - this block of code will be executed when the user hits "save"

    new_post_vc = InputViewController.alloc.init
    new_post_vc.completion_block = lambda do |author, content|
      new_post = Post.alloc.init
      new_post.author = author
      new_post.content = content

      new_post.remoteCreateAsync lambda do |error|
        if error
          AppDelegate.alertForError error
        else
          @posts.insert(0, new_post)
          self.tableView.reloadData
          self.dismissViewControllerAnimated(true, completion:nil)
        end
      end
    end

    new_post_vc.header = "Post something to NSRails.com!"
    new_post_vc.message_placeholder = "A comment about NSRails, a philosophical inquiry, or simply a \"Hello world\"!"

    nav = UINavigationController.alloc.initWithRootViewController new_post_vc

    self.navigationController.presentModalViewController nav, animated:true
  end
  
  def refresh
    # When the refresh button is hit, refresh our array of posts
      
    Post.remoteAllAsync lambda do |all_remote, error|
      if error
        AppDelegate.alertForError error
      else
        @posts = all_remote
        self.tableView.reloadData
      end
    end
  end
  
  def deletePostAtIndexPath(indexPath)
    post = @posts[indexPath.row]

    post.remoteDestroyAsync lambda do |error|
      if error
        AppDelegate.alertForError error
      else
        # Remember to delete the object from our local array too
        @posts.delete(post)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimationAutomatic)
      end
    end
  end
  
  # # # # # # # # #
  #
  # UI and table stuff
  #
  # # # # # # # # #
  
  def viewDidLoad
    super
    
    self.title = "Posts"
    self.tableView.rowHeight = 60

    # Add refresh button
    refreshBtn = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemRefresh, target:self, action:(:refresh))
    self.navigationItem.leftBarButtonItem = refreshBtn
    
    # Add + button
    addBtn = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemAdd, target:self, action:(:add))
    self.navigationItem.rightBarButtonItem = addBtn

    @posts = []
    refresh
  end
  
  def numberOfSectionsInTableView(tableView)
    1
  end
  
  def tableView(tableView, numberOfRowsInSection:section)
    return 0 if !@posts
    @posts.size
  end
  
  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cell = tableView.dequeueReusableCellWithIdentifier "Cell"
    if !cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:"Cell")
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator
    end
    
    p = @posts[indexPath.row]
    cell.textLabel.text = p.content
    cell.detailTextLabel.text = p.author
    
    cell
  end
  
  def tableView(tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:indexPath)
    deletePostAtIndexPath indexPath
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    post = @posts[indexPath.row]

    rvc = ResponsesViewController.alloc.initWithStyle UITableViewStyleGrouped
    rvc.post = post
    self.navigationController.pushViewController rvc, animated:true
  end
end