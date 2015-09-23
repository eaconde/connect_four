class PlayController < ApplicationController
  def pvp
    @p1 = current_user
    p "PLAYER 1 === #{@p1.to_json}"
    # this will be replaced once multiplayer games are supported
    @p2 = Player.get_or_create_fake

    @game = Game.new_game(@p1, @p2, request.session_options[:id])
    gon.game = @game
    @game
  end

  private

  def play_params
    params.require(:play).permit(:title, :p1, :p2, :winner_id, moves: [:game_id, :x_pos, :y_pos, :player_id])
  end
end
