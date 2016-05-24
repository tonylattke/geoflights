Rails.application.routes.draw do
  root 'home#index'
  get 'home' => 'home#index'
  
  get 'airports' => 'home#airports'

  get 'connections_airports/:route/:id/:name/:longitude/:latitude' => 'home#connections_airports', :constraints => {:name => /[A-Za-z0-9 ,.?!%&()'@$-_:;\"\\]+/, :latitude => /\-?\d+(.\d+)?/, :longitude => /\-?\d+(.\d+)?/}

  get 'countries' => 'home#countries'

  get 'airline/:id/:name' => 'home#airline_airports', :constraints => {:name => /[A-Za-z0-9 ,.?!%&()'@$-_:;\"\\]+/}
end
