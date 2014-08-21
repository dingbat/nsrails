class Response < ActiveRecord::Base
  belongs_to :post
  accepts_nested_attributes_for :post
  
  validates :content, :presence => true
  validates :author, :presence => true
  validate :deny_profanity  
    
  private
  def deny_profanity
    error = "can't be profane (!)"
    errors.add :content, error if ProfanityFilter::Base.profane?(content)
    errors.add :author, error if ProfanityFilter::Base.profane?(author)
  end
end
