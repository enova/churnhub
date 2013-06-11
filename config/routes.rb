Churnhub::Application.routes.draw do
  resources :repositories, except: [:show]
  resources :commits, only: [:show]

  get '/*url/commits(/:start(/to/:finish))' => "commits#index", as: :commits

  root to: "repositories#index"
end
