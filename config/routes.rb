resources :worklogs do
  collection do
    get 'my'
    post 'preview'
    get 'review'
    post 'review'
  end
end
