class Response < ActiveRecord::Base
  belongs_to :post
  
  validates_presence_of :body
  validates_presence_of :author
end
