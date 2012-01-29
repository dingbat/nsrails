class Brain < ActiveRecord::Base
  belongs_to :person
  has_many :thoughts
  
  accepts_nested_attributes_for :thoughts, :allow_destroy => true
end
