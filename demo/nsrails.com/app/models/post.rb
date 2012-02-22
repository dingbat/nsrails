class Post < ActiveRecord::Base
  has_many :responses
  
  validates_presence_of :body
  validates_presence_of :author
  
  accepts_nested_attributes_for :responses
  
  validate :deny_profanity
  
  private
  def deny_profanity
    if ProfanityFilter::Base.profane?(body)
      errors.add :body, 'profanity'
    end
    if ProfanityFilter::Base.profane?(author)
      errors.add :author, 'profanity'
    end
  end
end
