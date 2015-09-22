class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name, :limit => 100, :null => false
      t.string :session_id, :limit => 255, :null => false

      t.timestamps null: false
    end
  end
end
