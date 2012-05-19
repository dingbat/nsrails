class InputViewController < UIViewController
  attr_accessor :completion_block, :header, :message_placeholder
  
  # # # # # # # # #
  #
  #  This class has nothing to do with NSRails - all it does to get user input
  #
  # # # # # # # # #
  
  def cancel
    self.dismissModalViewControllerAnimated true
  end
  
  def save
    author = @author_field.text
    message = (@content_field.tag == 0 ? "" : @content_field.text) # blank if still on placeholder (tag 0)

    # If the block returned true (it worked), we should dismiss
    self.cancel if @completion_block.call(author, message)
  end
  
  def viewDidLoad
    super

    self.view.backgroundColor = UIColor.colorWithWhite(0.95, alpha:1.0)

    # Add cancel button
    cancel = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemCancel, target:self, action:(:cancel))
    self.navigationItem.leftBarButtonItem = cancel
    
    # Add save button
    save = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemSave, target:self, action:(:save))
    self.navigationItem.rightBarButtonItem = save
    
    self.title = "New Post"
    
    @header_label = UILabel.alloc.initWithFrame CGRectMake(14, 13, 293, 21)
    @header_label.backgroundColor = UIColor.clearColor
    @header_label.font = UIFont.fontWithName "GillSans-Bold", size:17
    @header_label.text = @header
    self.view.addSubview @header_label

    @author_field = UITextField.alloc.initWithFrame CGRectMake(15, 44, 292, 31)
    @author_field.placeholder = "First name"
    @author_field.backgroundColor = UIColor.whiteColor
    @author_field.borderStyle = UITextBorderStyleNone
    @author_field.font = UIFont.systemFontOfSize 17
    @author_field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter
    self.view.addSubview @author_field
    
    @content_field = UITextView.alloc.initWithFrame CGRectMake(15, 87, 292, 104)
    @content_field.delegate = self
    @content_field.backgroundColor = UIColor.whiteColor
    @content_field.font = UIFont.systemFontOfSize 16
    self.view.addSubview @content_field

    # Make the fields look nice and round
    @content_field.layer.cornerRadius = 4
    @content_field.layer.borderColor = UIColor.grayColor.CGColor
    @content_field.layer.borderWidth = 1
    
    @author_field.layer.cornerRadius = 4
    @author_field.layer.borderColor = UIColor.grayColor.CGColor
    @author_field.layer.borderWidth = 1
    
    # Add some space to side of authorField
    padding_view = UIView.alloc.initWithFrame CGRectMake(0, 0, 5, 20)
    @author_field.leftView = padding_view
    @author_field.leftViewMode = UITextFieldViewModeAlways
    
    # Start off the textview with the placeholder text
    placehold
    
    # Focus on authorField
    @author_field.becomeFirstResponder
  end
  
  #
  #  Code for the placeholder in the message textview, which isn't built-in into iOS
  #
  
  def select_beginning
    range = @content_field.textRangeFromPosition @content_field.beginningOfDocument, toPosition:@content_field.beginningOfDocument
    @content_field.setSelectedTextRange range
  end
  
  def placehold
    @content_field.text = message_placeholder
    @content_field.textColor = UIColor.lightGrayColor
    @content_field.tag = 0

    select_beginning
  end

  def textView(textView, shouldChangeTextInRange:range, replacementText:text)
    if text.empty? && ((range.length > 0 && range.length == textView.text.length) || (textView.tag == 0))
  		placehold
      return false
    else
      if textView.tag == 0
        textView.text = ""
      end
      textView.textColor = UIColor.blackColor
      textView.tag = 1
    end
    true
  end

  def textViewShouldEndEditing(textView)
    if textView.text.empty?
      placehold
    end
  	true
  end

  def textViewShouldBeginEditing(textView)
    if textView.tag == 0
      select_beginning
    end
    true
  end

  def textViewDidChangeSelection(textView)
    if textView.tag == 0
      # Make it temporarily -1 to not start an infinite loop after next line
      textView.tag = -1
      # Move selection to beginning (now with tag -1)
      select_beginning
      # Back to 0
      textView.tag = 0
    end
  end
end