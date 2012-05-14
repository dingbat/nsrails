class Post < NSRailsModel
  attr_writer :author, :content, :responses, :createdAt

  # Right now there's a bug in RubyMotion that requires you to define getter methods manually
  # Soon you'll be able just do "attr_accessor" above instead of this
  def author; @author; end  
  def content; @content; end
  def responses; @responses; end
  def createdAt; @createdAt; end
  
   
  # Define the NSRailsSync macro as usual, only as a class method returning a string
  # Remember that in the Ruby environment, * is not supported, has_many relationships have to be indicated with '-m', and dates must declared with NSDate
  def self.NSRailsSync
    'author, content, createdAt:NSDate, responses:Response -m'
  end
    
  # For responses, since it's an array, -m is required (has-many). The ":" is required to define an association with another class.
  # In this case, the class of objects we want to fill our responses array with is Response (must be an NSRailsModel subclass)
  
  # For createdAt, :NSDate makes it so NSRails will automatically convert to a formatted date object (string) when sending to Rails, and return a Time object when retrieving. Handy.
end