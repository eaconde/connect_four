class AddSessionIdToGame < ActiveRecord::Migration
  def change
    add_column :games, :session_id, :string
  end
end
