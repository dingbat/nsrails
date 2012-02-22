class Post < ActiveRecord::Base
  has_many :responses
  
  validates_presence_of :body
  validates_presence_of :author
  
  accepts_nested_attributes_for :responses
end
