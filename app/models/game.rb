class Game < ActiveRecord::Base
  belongs_to :player
  has_many :moves
   accepts_nested_attributes_for :moves

  def self.new_game(player1)
    # game has its own session.
    # TODO: session should be updated to player so game state can be reloaded in case of disconnection
    # ie. /play/pvp?session_id=1234567890 <= loading game by session.
    # NOTE: design consideration. multiple sessions/player?
    session_id = SecureRandom.hex(32)
    ##{player1.name} vs. #{player2.name}
		Game.find_or_create_by(:title => "Waiting for opponent...") do |game|
      game.session_id = session_id
  		game.p1 = player1.id
  		# game.p2 = player2.id
    end
	end

  def join(player2)
    player1 = Player.find(self.p1)
    player2 = Player.find(player2)
    self.title = "#{player1.name} vs. #{player2.name}"
    self.p2 = player2
    self.save
  end
end
