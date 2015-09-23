class Game < ActiveRecord::Base
  belongs_to :player
  has_many :moves
   accepts_nested_attributes_for :moves

  def self.new_game(player1, player2, session_id)
		Game.find_or_create_by(:title => "#{player1.name} vs. #{player2.name}") do |game|
      game.session_id = session_id
  		game.p1 = player1.id
  		game.p2 = player2.id
    end
	end
end
