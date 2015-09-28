class PlayController < ApplicationController
  before_action :set_game, only: [:join, :complete, :destroy]

  def index
    @games = Game.available

    gon.push({
      games: @games,
      root_url: root_url
    })
    @games
  end

  def pvp
    @player1 = current_player

    @game = Game.new_game @player1
    message = {
      game: @game
    }
    Server.delay.broadcast "/play/new", message
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

      puts "API JOIN: #{@player2.to_json}"
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

      Server.broadcast "/play/#{@game.id}/join", message
      render 'play/pvp'
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  def complete
    if @game.complete(play_params[:winner_id])
      Server.broadcast "/play/#{@game.id}/completed", @game
      render json: @game, status: :ok, location: @recurring_promo
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  def destroy
    puts "destroy game == #{@game.to_json}"
    game_id = @game.id
    @game.destroy
    message = {
      id: game_id,
      message: "Game is no longer available"
    }
    Server.broadcast "/play/#{game_id}/destroyed", message
    head :no_content
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def play_params
    params.require(:play).permit(:title, :p1, :p2, :winner_id, moves: [:game_id, :x_pos, :y_pos, :player_id])
  end
end
