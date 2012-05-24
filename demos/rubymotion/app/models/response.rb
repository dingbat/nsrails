class Response < NSRRemoteObject  
  attr_accessor :author, :content, :post

  # Right now there's a bug in RubyMotion that requires you to define getter methods manually
  # Hopefully soon you'll be able delete all of this
  def author; @author; end  
  def content; @content; end
  def post; @post; end
  
  def self.NSRMap
    'author, content, post:Post -b'
  end
    
  # The NSRMap above will sync all properties w/Rails, and specially flag "post" to behave as a belongs_to association
   
  # ==================
  # If you're curious about the "-b" flag:
  # ==================
  # 
  # The "-b" flag for the "post" property indicates that a Response belongs_to a post!
  # 
  # This flag is not necessary (even if it's a belongs_to relation), but it allows us to create new Responses already attached to a specific Post, without having to update the Post object.
  # 
  # Here's an example:
  # 
  #    new_resp = Response.alloc.init
  #    new_resp.author = author
  #    new_resp.content = content
  #    new_resp.post = pre_existing_post   <-- this line
  # 
  #    newResp.remoteCreate(p)
  # 
  # In the marked line, we're setting the "post" property to a living, breathing, Post object, but NSRails knows to only send "post_id" instead of hashing out the entire Post object and sticking it into "post_attributes", which Rails would reject.
  # 
  # Of course, this is only relevant for belongs_to since you'd typically *want* the "_attributes" key in most cases.
  # 
  # See the Wiki ( https://github.com/dingbat/nsrails/wiki ) for more, specifically under NSRMap ( https://github.com/dingbat/nsrails/wiki/NSRMap )
end