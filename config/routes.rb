Churnhub::Application.routes.draw do
  resources :repositories, except: [:show]

  get '/*url/commits/(:sha)' => "commits#show", sha: /[0-9a-fA-F]+/
  get '/*url/commits(/:start(/to/:finish))' => "commits#index", as: :commits

  root to: "repositories#index"
end
