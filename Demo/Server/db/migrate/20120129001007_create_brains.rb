class CreateBrains < ActiveRecord::Migration
  def change
    create_table :brains do |t|
      t.integer :person_id
      t.string :size

      t.timestamps
    end
  end
end
