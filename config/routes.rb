Rails.application.routes.draw do

  root to: 'home#index'
  get 'play/pvp'
  scope "play/:id", defaults: {format: :json} do
    resource :moves, only: [:index, :create]
  end


end
