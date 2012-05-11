class Post < NSRailsModel
  # Setters and getters must be manually defined for now since attr_accessor doesn't play nicely yet
  def author; @author; end  
  def content; @content; end
  def responses; @responses; end  
  def setAuthor(a); @author = a; end
  def setContent(c); @content = c; end
  def setResponses(r); @responses = r; end
   
  # Define the NSRailsSync macro as usual, only as a class method returning a string
  # Remember that * is not supported in the Ruby environment
  def self.NSRailsSync
    'author, content, responses:Response'
  end
    
  # For responses, since it's an array, the ":" is required to define an association with another class.
  # In this case, the class of objects we want to fill our responses array with is Response (must be an NSRailsModel subclass)
end