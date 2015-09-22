Rails.application.routes.draw do
  root to: 'home#index'
  get 'play/index'
end
