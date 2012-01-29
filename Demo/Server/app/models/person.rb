class Person < ActiveRecord::Base
  has_one :brain
  has_many :thoughts, :through => :brain
  
  validates_presence_of :name
  
  accepts_nested_attributes_for :brain
end
