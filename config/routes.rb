Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :users, :controller => "modo"
  resources :memberships, :controller => "membership"
end
