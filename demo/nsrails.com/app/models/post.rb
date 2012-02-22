class Post < ActiveRecord::Base
  has_many :responses, :dependent => :destroy
  
  validates_presence_of :body
  validates_presence_of :author
  
  accepts_nested_attributes_for :responses
  
  validate :deny_profanity
  
  private
  def deny_profanity
    if ProfanityFilter::Base.profane?(body) || ProfanityFilter::Base.profane?(author)
      errors.add :base, 'profanity'
    end
  end
end
