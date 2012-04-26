class AddIndexToRelationshipColumn < ActiveRecord::Migration
  def change
    add_index :responses, :post_id, :unique => true
  end
end
