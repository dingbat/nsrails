class Response < NSRRemoteObject  
  attr_accessor :author, :content, :post
    
  def remoteProperties
    super + ["author", "content", "post"]
  end
  
  def relationshipForProperty(property)
    NSRRelationship.belongsTo(Post) if property == "post" || super
  end
end
 
=begin

==================
Note:
==================

Overriding relationshipForProperty: above is not necessary. By default, (if it's not overridden), NSRails will detect that 'post' is of type Post (which is an NSRRemoteObject subclass), and will treat it as a hasOne: relationship.

* The hasOne relationship means that when sending a Response, 'post' will be sent as a dictionary with remote key 'post_attributes'.

* The belongsTo relationship means that when sending a Response, only the remoteID from 'post' will be sent, with the remote key 'post_id'

  This means that you don't need to define a postID attribute in your Response class, assign it a real Post object, and still have Rails be chill when receiving it! (Rails gets angry if you send it _attributes for a belongs-to relation.)

  Of course, this is only relevant for belongs-to since you'd typically *want* the "_attributes" key in most cases. 
    
=end