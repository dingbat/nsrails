class Response < NSRRemoteObject  
  attr_accessor :author, :content, :post
    
  def remoteProperties
    super + ["author", "content", "post"]
  end
  
  def nestedClassForProperty(property)
    Post if property == "post"
  end
  
  def shouldOnlySendIDKeyForNestedObjectProperty(property)
    (property == "post")
  end
end
 
=begin

==================
Note:
==================

Overriding shouldOnlySendIDKeyForNestedObjectProperty above is necessary for any relationships that are 'belongs-to' on Rails.

* Returning NO means that when sending a Response, 'post' will be sent as a dictionary with remote key 'post_attributes'.

* Returning YES means that when sending a Response, only the remoteID from 'post' will be sent, with the remote key 'post_id'


This means that you don't need to define a postID attribute in your Response class, assign it a real Post object, and still have Rails be chill when receiving it! (Rails gets angry if you send it _attributes for a belongs-to relation.)

Of course, this is only relevant for belongs-to since you'd typically *want* the "_attributes" key in most cases.
    
=end