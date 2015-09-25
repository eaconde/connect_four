class PlayController < ApplicationController
  before_action :set_game, only: [:join, :complete]

  def index
    @games = Game.all
  end

  def pvp
    @player1 = current_player

    @game = Game.new_game @player1
    gon.push({
      player1: @player1,
      game: @game
    })
    @game
  end

  def join
    if @game.join play_params[:p2]
      @player1 = Player.find(@game.p1)
      @player2 = Player.find(play_params[:p2])
      gon.push({
        player1: @player1,
        player2: @player2,
        game: @game
      })

      message = {
        player1: @player1,
        player2: @player2,
        game: @game
      }

      broadcast "/play/#{@game.id}/join", message
      render 'play/pvp'
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  def complete
    if @game.complete(play_params[:winner_id])
      broadcast "/play/#{@game.id}/completed", @game
      render json: @game, status: :ok, location: @recurring_promo
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
