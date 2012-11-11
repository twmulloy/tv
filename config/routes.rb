Tv::Application.routes.draw do
  resources :sites

  root :to => 'home#index'
end
