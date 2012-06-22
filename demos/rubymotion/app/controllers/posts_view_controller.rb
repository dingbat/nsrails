class PostsViewController < UITableViewController
  def add
    # When the + button is hit, display an InputViewController (this is the shared input view for both posts and responses)
    # It has an init method that accepts a completion block - this block of code will be executed when the user hits "save"

    new_post_vc = InputViewController.alloc.init
    new_post_vc.completion_block = lambda do |author, content|
      new_post = Post.alloc.init
      new_post.author = author
      new_post.content = content

      ptr = Pointer.new(:object)
      if !new_post.remoteCreate(ptr)
        AppDelegate.alertForError ptr[0]
        # Don't dismiss the input VC
        return false
      end

      @posts.insert(0, new_post)
      self.tableView.reloadData

      true
    end

    new_post_vc.header = "Post something to NSRails.com!"
    new_post_vc.message_placeholder = "A comment about NSRails, a philosophical inquiry, or simply a \"Hello world\"!"

    nav = UINavigationController.alloc.initWithRootViewController new_post_vc

    self.navigationController.presentModalViewController nav, animated:true
  end
  
  def refresh
    # When the refresh button is hit, refresh our array of posts (uses an extension on Array)
  	
    e_ptr = Pointer.new(:object)
    c_ptr = Pointer.new(:boolean)
    
    if !@posts.remoteFetchAll(Post, error:e_ptr, changes:c_ptr)
      AppDelegate.alertForError e_ptr[0]
    elsif c_ptr[0]
      self.tableView.reloadData
    end
    
    # This could also be done by setting @posts to the result of Post.remoteAll(e_ptr), but using the Array method will persist the same objects and update their respective properties instead of replacing everything, which could be desirable
  end
  
  def deletePostAtIndexPath(indexPath)
    post = @posts[indexPath.row]

    p = Pointer.new(:object)
    if post.remoteDestroy(p)
      # Remember to delete the object from our local array too
      @posts.delete(post)
      self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimationAutomatic)
    else
      AppDelegate.alertForError p[0]
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