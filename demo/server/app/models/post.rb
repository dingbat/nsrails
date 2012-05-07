class Post < ActiveRecord::Base
  has_many :responses, :dependent => :destroy
  accepts_nested_attributes_for :responses
  
  validates :content, :presence => true
  validates :author, :presence => true
  validate :deny_profanity  
    
  private
  def deny_profanity
    errors.add :content, "can't have profanity" if ProfanityFilter::Base.profane?(content)
    errors.add :author, "can't have profanity" if ProfanityFilter::Base.profane?(author)
  end
end
