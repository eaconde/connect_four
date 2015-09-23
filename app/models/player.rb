class Player < ActiveRecord::Base
  has_many :games

  def self.get_or_create_fake
    self.find_or_create_by(name: "Player 2") do |user|
      user.session_id = "second_player_application_generated"
    end
  end

end
