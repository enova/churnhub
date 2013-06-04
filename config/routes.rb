Churnhub::Application.routes.draw do
  resources :repositories, except: [:show]

  get '/*url/commits(/:start(/to/:finish))' => "commits#index", as: :commits
  get "/repo/*url" => "repositories#show", as: :repo

  root to: "repositories#index"
end
