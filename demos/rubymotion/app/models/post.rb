class Post < NSRRemoteObject
  attr_accessor :author, :content, :responses, :created_at
  
  def remoteProperties
    super + ["author", "content", "responses", "created_at"]
  end
  
  def relationshipForProperty(property)
    case property
    when "responses"
      NSRRelationship.hasMany(Response)
    else
      super
    end
  end
end