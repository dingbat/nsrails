class AddFieldsToResponse < ActiveRecord::Migration
  def change
    add_column :responses, :content, :text
    add_column :responses, :author, :string
    add_column :responses, :post_id, :integer
  end
end
