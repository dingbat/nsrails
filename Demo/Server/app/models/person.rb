class Person < ActiveRecord::Base
  has_one :brain
  has_many :thoughts, :through => :brain
  
  accepts_nested_attributes_for :brain
end
