class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    if session[:player_id].nil? then
      session[:player_id] = Player.create(:name => 'P1', :session_id => request.session_options[:id]).id
    end

    return @current_user ||= Player.find_by_id(session[:player_id])
  end
end
