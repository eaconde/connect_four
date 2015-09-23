class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?

  def broadcast(channel, data)
    message = {:channel => channel, :data => data, :ext => {:auth_token => 'anything'}}
    uri = URI.parse("http://faye-cedar.herokuapp.com/faye")
    Net::HTTP.post_form(uri, :message => message.to_json)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :name
    devise_parameter_sanitizer.for(:account_update) << :name
  end

end
