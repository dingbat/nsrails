class Post < NSRailsModel
  attr_writer :author, :content, :responses

  # Right now there's a bug in RubyMotion that requires you to define getter methods manually
  # Soon you'll be able just do "attr_accessor" above instead of this
  def author; @author; end  
  def content; @content; end
  def responses; @responses; end  
  
   
  # Define the NSRailsSync macro as usual, only as a class method returning a string
  # Remember that * is not supported in the Ruby environment, and has_many relationships have to be indicated with '-m'
  def self.NSRailsSync
    'author, content, responses:Response -m'
  end
    
  # For responses, since it's an array, the ":" is required to define an association with another class.
  # In this case, the class of objects we want to fill our responses array with is Response (must be an NSRailsModel subclass)
end