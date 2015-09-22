class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :title, :limit => 100, :null => false
      t.integer :p1
      t.integer :p2
      t.integer :winner_id

      t.timestamps null: false
    end
  end
end
