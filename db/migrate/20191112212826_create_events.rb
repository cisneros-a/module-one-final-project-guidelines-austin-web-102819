class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :name
      t.string :location
      t.string :date
      t.string :type
      t.integer :price
      t.string :description
    end
  end
 end 
