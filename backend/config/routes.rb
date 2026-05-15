Rails.application.routes.draw do
  namespace :api do
    get :search, to: 'search#index'
  end
end