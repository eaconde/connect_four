Rails.application.routes.draw do
  root to: 'play#index'
  # TODO: convert routes to resource
  # games listing
  get 'play' => 'play#index'
  # new game
  get 'play/pvp'
  # join game
  post 'play/join'
  # finish game
  put "play/:id/complete" => 'play#complete'
  # finish game
  post "play/reset" => 'play#reset'
  # leave game
  delete "play/:id" => 'play#destroy'
  # moves tracking
  scope "play/:id", defaults: {format: :json} do
    resource :moves, only: [:index, :create]
  end
  # player authentication
  devise_for :players
end
