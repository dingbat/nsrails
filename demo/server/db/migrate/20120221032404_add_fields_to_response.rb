class AddFieldsToResponse < ActiveRecord::Migration
  def change
    add_column :responses, :content, :text
    add_column :responses, :author, :string
    add_column :responses, :post_id, :integer
    add_index :responses, :post_id, :unique => true
  end
end