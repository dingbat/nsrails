class Response < ActiveRecord::Base
  belongs_to :post
  
  validate :content, :presence => true
  validate :author, :presence => true
end
