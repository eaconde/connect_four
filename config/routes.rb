Rails.application.routes.draw do
  root to: 'play#index'
  get 'play' => 'play#index'
  get 'play/pvp'
  scope "play/:id", defaults: {format: :json} do
    resource :moves, only: [:index, :create]
  end


end
