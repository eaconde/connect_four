class PlayController < ApplicationController
  before_action :set_game, only: [:join]

  def index
    @games = Game.all
  end

  def pvp
    @p1 = current_player
    p "PLAYER 1 === #{@p1.to_json}"
    # this will be replaced once multiplayer games are supported
    # @p2 = Player.get_or_create_fake

    @game = Game.new_game @p1 #, @p2)
    gon.game = @game
    @game
  end

  def join
    if @game.join play_params[:p2]
      gon.game = @game
      broadcast '/player/join', @game
      render 'play/pvp'
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])

  end

  def play_params
    params.require(:play).permit(:title, :p1, :p2, :winner_id, moves: [:game_id, :x_pos, :y_pos, :player_id])
  end
end
