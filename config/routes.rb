Rails.application.routes.draw do
  root "pages#landing"
  get "about" => "pages#about"
  get "guide" => "pages#guide"

  # typle-r's addresses for signing in and the account pages around it; each keeps ?returnTo= (the page to come back to).
  get "signin" => "sessions#new", as: :new_session
  resource :session, only: %i[create destroy]
  get "signup" => "registrations#new", as: :new_registration
  resource :registration, only: :create
  get "forgot-password" => "passwords#new", as: :new_password
  post "forgot-password" => "passwords#create", as: :passwords
  get "reset-password" => "passwords#edit", as: :edit_password
  put "reset-password" => "passwords#update", as: :password
  get "forgot-id" => "login_id_reminders#new", as: :new_login_id_reminder
  post "forgot-id" => "login_id_reminders#create", as: :login_id_reminder
  get "email_confirmations/:token" => "email_confirmations#show", as: :email_confirmation
  post "auth/github/callback" => "omniauth_callbacks#github"
  get "auth/github/callback" => "omniauth_callbacks#github"
  get "auth/failure" => "omniauth_callbacks#failure"

  resource :account, only: :show do
    patch :password, action: :update_password
    post :verification, action: :resend_verification
    delete :sessions, action: :sign_out_everywhere
  end
  # typle-r's URLs: /settings is 一般 (the language and the account), /input is 入力.
  get "settings" => "settings#general", as: :general_settings
  get "input" => "settings#show", as: :input_settings
  patch "settings" => "settings#update", as: :settings
  patch "settings/locale" => "settings#locale", as: :locale_settings
  get "settings/general", to: redirect("/settings")
  resources :devices, only: %i[index create update destroy] do
    collection { post :choose }
  end
  resource :interests, only: %i[show update] do
    patch :packs
  end

  get "home" => "home#show"
  get "play" => "practice#show"

  resources :practice_records, only: %i[index show create destroy], path: "records"
  get "rankings" => "rankings#index"

  resources :packs do
    resources :word_lists, shallow: true, except: %i[index show] do
      member do
        get :export
        post :weak_review
        post :copy
      end
    end
    member do
      get :export
      post :copy
    end
    collection { post :import }
  end
  get "words" => "words#index"
  # typle-r's /create: a new list, into one of the user's packs or a new one.
  get "create" => "word_lists#new", as: :create_list
  post "create" => "word_lists#create"

  resources :catalog, only: %i[index show], controller: "catalog" do
    member do
      post :follow
      delete :unfollow
    end
  end

  # typle-r's pages kept for links handed out: a shared practice result, the licenses, an ended pack share and the gallery.
  get "result" => "shared_results#show", as: :shared_result
  get "about/licenses" => "pages#licenses", as: :licenses
  get "shared/:id" => "pages#shared_pack", as: :shared_pack
  get "gallery", to: redirect("/catalog")
  get "verify-email" => "email_confirmations#show", as: :verify_email

  get "up" => "rails/health#show", as: :rails_health_check

  get "404" => "errors#not_found"
  # Anything else is typle-r's 404 (kept last).
  match "*path" => "errors#not_found", via: :all, constraints: ->(request) { !request.path.start_with?("/rails/", "/assets/", "/handwriting/") }
end
