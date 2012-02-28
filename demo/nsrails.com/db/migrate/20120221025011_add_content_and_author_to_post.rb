class AddContentAndAuthorToPost < ActiveRecord::Migration
  def change
    add_column :posts, :content, :text
    add_column :posts, :author, :string
  end
end