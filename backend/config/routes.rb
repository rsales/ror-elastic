Rails.application.routes.draw do
  namespace :api do
    get :search,  to: 'search#index'
    get :suggest, to: 'suggest#index'
  end
end
