class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    session[:player_id] = nil
    if session[:player_id].nil? then
      session[:player_id] = Player.find_or_create_by(:name => 'Player 1', :session_id => request.session_options[:id]).id
    end

    return Player.find_by_id(session[:player_id])
  end
end
