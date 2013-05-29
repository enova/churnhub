Churnhub::Application.routes.draw do
  resources :repositories, except: [:show]

  get "/repo/*url" => "repositories#show", as: :repo

  root to: "repositories#index"
end
