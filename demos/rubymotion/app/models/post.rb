class Post < NSRRemoteObject
  attr_accessor :author, :content, :responses, :created_at
  
  def remoteProperties
    super + ["author", "content", "responses", "created_at"]
  end
  
  def nestedClassForProperty(property)
    Response if property == "responses"
  end
end