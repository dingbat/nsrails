class ResponsesViewController < UITableViewController
  attr_accessor :post

  def add
    new_post_vc = InputViewController.alloc.init
    new_post_vc.completion_block = lambda do |author, content|
      new_resp = Response.alloc.init
      new_resp.author = author
      new_resp.content = content
      new_resp.post = @post    # check out response.rb for more detail on how this line is possible
      
      p = Pointer.new(:object)
      if (!new_resp.remoteCreate(p))
        AppDelegate.alertForError p[0]
        return false
      end

      @post.responses.insert(0, new_resp)
      self.tableView.reloadData
		  
      # Instead of line 10 (the belongs_to trick), you could also add the new response to the post's "responses" array and then update it:
      # 
      #    post.responses << newResp
      #    post.remoteUpdate(error_ptr)
      # 
      # Doing this may be tempting since it'd already be in post's "responses" array, BUT: you'd have to take into account the Response validation failing (you'd then have to *remove it* from the array). Also, creating the Response rather than updating the Post will set newResp's remoteID, so we can do remote operations on it later!
      
      true
    end

    new_post_vc.header = "Write your response to #{@post.author}"
    new_post_vc.message_placeholder = "Your response"

    nav = UINavigationController.alloc.initWithRootViewController new_post_vc

    self.navigationController.presentModalViewController nav, animated:true
  end
  
  def deleteResponseAtIndexPath(indexPath)
    resp = @post.responses[indexPath.row]

    ptr = Pointer.new(:object)
    if (resp.remoteDestroy(ptr))
      # Remember to delete the object from our local array too
      @post.responses.delete(resp)

      self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimationAutomatic);
    else
      AppDelegate.alertForError(ptr[0])
    end
  	
    # If we wanted to batch-delete or something, we could also do:
    # 
    #    resp.remoteDestroyOnNesting = true
    #    # ... do the same for other post's other responses
    #    post.remoteUpdate(p)
    #
    # For this to work, you need to set `:allow_destroy => true` in Rails
  end
  
  #
  # UI and table stuff
  #
  def viewDidLoad
    self.title = "Responses"
    self.tableView.rowHeight = 60

    # Add reply button
    addBtn = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemReply, target:self, action:(:add))
    self.navigationItem.rightBarButtonItem = addBtn

    super
  end
  
  def numberOfSectionsInTableView(tableView)
    1
  end
  
  def tableView(tableView, titleForFooterInSection:section)
    str = ""
    if @post.responses.empty?
      str += "There are no responses to this post.\nSay something!\n\n"
    end
    str += "Posted on #{@post.created_at.strftime("%m/%d/%y")}"
  end
  
  def tableView(tableView, titleForHeaderInSection:section)
    "“#{post.content}”"
  end
  
  def tableView(tableView, numberOfRowsInSection:section)
    @post.responses.size
  end
  
  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cell = tableView.dequeueReusableCellWithIdentifier("Cell")
    if !cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:"Cell")
      cell.selectionStyle = UITableViewCellSelectionStyleNone
    end
    
    r = @post.responses[indexPath.row]
    cell.textLabel.text = r.content
    cell.detailTextLabel.text = r.author
    
    cell
  end
  
  def tableView(tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:indexPath)
    deleteResponseAtIndexPath(indexPath)
  end
end