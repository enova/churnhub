Churnhub::Application.routes.draw do
  resources :repositories
  get "/repo/*url" => "repositories#repo", as: :repo

  root to: "repositories#index"
end
