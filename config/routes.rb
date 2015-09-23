Rails.application.routes.draw do
  root to: 'play#index'
  # games listing
  get 'play' => 'play#index'
  # new game
  get 'play/pvp'
  # join game
  post 'play/join'
  # moves tracking
  scope "play/:id", defaults: {format: :json} do
    resource :moves, only: [:index, :create]
  end
  # player authentication
  devise_for :players
end
