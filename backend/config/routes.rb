Rails.application.routes.draw do
  namespace :api do
    get :health, to: "health#show"
    get :search, to: "search#index"
    get :suggest, to: "suggest#index"
    get "movies/:id", to: "movies#show", as: :movie
  end
end
