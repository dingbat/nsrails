class Response < ActiveRecord::Base
  belongs_to :post
  
  validates_presence_of :content
  validates_presence_of :author
end
