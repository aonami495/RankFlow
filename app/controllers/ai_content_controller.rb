# frozen_string_literal: true

class AiContentController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, only: [:article_suggestions]
  before_action :set_article, only: [:article_suggestions]

  def index
    @sites = current_user.sites
  end

  def generate_titles
    keyword = params[:keyword]
    current_title = params[:current_title]

    if keyword.blank?
      render json: { error: "Keyword is required" }, status: :unprocessable_entity
      return
    end

    service = AiContentService.new
    titles = service.generate_title_suggestions(
      keyword: keyword,
      current_title: current_title,
      count: 5
    )

    render json: { titles: titles }
  end

  def generate_outline
    keyword = params[:keyword]
    title = params[:title]

    if keyword.blank? || title.blank?
      render json: { error: "Keyword and title are required" }, status: :unprocessable_entity
      return
    end

    service = AiContentService.new
    outline = service.generate_outline(keyword: keyword, title: title)

    render json: { outline: outline }
  end

  def article_suggestions
    keywords = @article.keywords.includes(:rank_histories)

    service = AiContentService.new
    suggestions = service.generate_rewrite_suggestions(
      article: @article,
      keywords: keywords
    )

    respond_to do |format|
      format.html { render partial: "suggestions", locals: { suggestions: suggestions, article: @article } }
      format.json { render json: suggestions }
    end
  end

  def generate_meta
    keyword = params[:keyword]
    current_description = params[:current_description]

    if keyword.blank?
      render json: { error: "Keyword is required" }, status: :unprocessable_entity
      return
    end

    service = AiContentService.new
    description = service.improve_meta_description(
      keyword: keyword,
      current_description: current_description
    )

    render json: { description: description }
  end

  private

  def set_site
    @site = current_user.sites.find(params[:site_id])
  end

  def set_article
    @article = @site.articles.find(params[:article_id])
  end
end
