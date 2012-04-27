class Post < ActiveRecord::Base
  has_many :responses, :dependent => :destroy
  
  validates :content, :presence => true
  validates :author, :presence => true
  
  accepts_nested_attributes_for :responses
  
  validate :deny_profanity
  
  private
  def deny_profanity
    if ProfanityFilter::Base.profane?(content) || ProfanityFilter::Base.profane?(author)
      errors.add :base, 'profanity'
    end
  end
end
