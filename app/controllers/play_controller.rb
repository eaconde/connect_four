class PlayController < ApplicationController
  def pvp
    @p1 = current_user
    p "PLAYER 1 === #{@p1.to_json}"
    # this will be replaced once multiplayer games are supported
    @p2 = Player.get_or_create_fake

    @game = Game.new_game(@p1, @p2, request.session_options[:id])
    @game
  end
end
