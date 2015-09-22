class PlayController < ApplicationController
  def index
    p1 = current_user
    # this will be replaced once multiplayer games are supported
    p2 = Player.create_fake

    @game = Game.new_game(p1, p2)
    puts "#{p1.to_json} || #{p2.to_json} || #{@game.to_json}"
    @game
  end
end
