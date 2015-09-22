class CreateMoves < ActiveRecord::Migration
  def change
    create_table :moves do |t|
      t.integer :game_id
      t.integer :player_id
      t.integer :x_pos
      t.integer :y_pos

      t.timestamps null: false
    end
  end
end
