class AddBodyAndAuthorToPost < ActiveRecord::Migration
  def change
    add_column :posts, :body, :text
    add_column :posts, :author, :string
  end
end