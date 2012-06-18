class Post < NSRRemoteObject
  attr_accessor :author, :content, :responses, :created_at
  
  def remoteProperties
    super + ["author", "content", "responses", "created_at"]
  end
  
  def relationshipForProperty(property)
    NSRRelationship.hasMany(Response) if property == "responses" || super  
  end
end