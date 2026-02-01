# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # Sites with nested keywords and articles
  resources :sites do
    resources :keywords, except: [:index] do
      resources :comments, only: %i[create edit update destroy]
    end
    resources :articles
    resources :asp_connections, except: [:show] do
      member do
        post :sync
      end
    end
    resources :competitors
    resources :team_memberships, except: %i[show edit]
    resources :comments, only: %i[create edit update destroy]
  end

  # Alerts
  resources :alerts, only: [:index, :show] do
    member do
      patch :mark_as_read
    end
    collection do
      post :mark_all_as_read
    end
  end

  # Rewrite suggestions
  get "rewrite_suggestions", to: "rewrite_suggestions#index"

  # Keyword Research
  get "keyword_research", to: "keyword_research#index"
  get "keyword_research/search", to: "keyword_research#search", as: :search_keyword_research

  # AI Content
  get "ai_content", to: "ai_content#index"
  post "ai_content/generate_titles", to: "ai_content#generate_titles"
  post "ai_content/generate_outline", to: "ai_content#generate_outline"
  post "ai_content/generate_meta", to: "ai_content#generate_meta"
  get "sites/:site_id/articles/:article_id/ai_suggestions", to: "ai_content#article_suggestions", as: :article_ai_suggestions

  # Revenues
  resources :revenues

  # Reports
  resources :reports, only: [:index, :show]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Root path
  root "dashboard#index"
end
