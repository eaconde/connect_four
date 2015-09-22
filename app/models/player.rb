class Player < ActiveRecord::Base
  has_many :games

  def self.create_fake
    player = self.new
		player.name = "Fake P2"
		player.session_id = "second_player_application_generated"
    player.save
    player
  end

end
