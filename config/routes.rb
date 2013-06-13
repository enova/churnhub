Churnhub::Application.routes.draw do
  resources :repositories, only: [:create]
  resources :commits, only: [:show]

  get '/signin'  => "session#signin"
  get '/auth'    => "session#auth"
  get '/signout' => "session#signout"

  get '/*url/commits(/:start(/to/:finish))' => "commits#index", as: :commits

  root to: "repositories#index"
end
