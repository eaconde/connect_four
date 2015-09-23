class PlayController < ApplicationController
  before_action :set_game, only: [:join]

  def index
    @games = Game.all
  end

  def pvp
    @player1 = current_player
    @game = Game.new_game @player1
    gon.player1 = @p1
    gon.game = @game
    @game
  end

  def join
    if @game.join play_params[:p2]
      gon.game = @game
      @player2 = Player.find(play_params[:p2])
      gon.player2 = @player2
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
