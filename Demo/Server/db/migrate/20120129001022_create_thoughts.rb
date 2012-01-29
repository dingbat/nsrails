class CreateThoughts < ActiveRecord::Migration
  def change
    create_table :thoughts do |t|
      t.integer :brain_id
      t.string :content

      t.timestamps
    end
  end
end
