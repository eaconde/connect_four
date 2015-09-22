class Game < ActiveRecord::Base
  belongs_to :player
  has_many :moves

  def self.new_game(player1, player2)
		game = Game.new(:title => "#{player1.name} vs. #{player2.name}")
		game.p1 = player1
		game.p2 = player2
		game.save
    game
	end
end
