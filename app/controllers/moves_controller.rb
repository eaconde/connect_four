class MovesController < ApplicationController
  def index
    @moves = Move.where(["game_id = ?", params[:id]])
    gon.moves = @moves
  end

  def create
    @move = Move.new(move_params)
    if @move.save
      render json: @move
    else
      render json: @move.errors, status: :unprocessable_entity
    end
  end

  private

  def move_params
    params.require(:move).permit(:game_id, :x_pos, :y_pos, :player_id)
  end

end
