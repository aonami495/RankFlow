# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site
  before_action :set_article, only: [:show, :edit, :update, :destroy]

  def index
    @articles = @site.articles.includes(:keywords).order(created_at: :desc)
  end

  def show
    @keywords = @article.keywords.includes(:rank_histories)
  end

  def new
    @article = @site.articles.build(status: "draft")
  end

  def create
    @article = @site.articles.build(article_params)

    if @article.save
      redirect_to site_article_path(@site, @article), notice: "Article was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to site_article_path(@site, @article), notice: "Article was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to site_articles_path(@site), notice: "Article was successfully deleted."
  end

  private

  def set_site
    @site = current_user.sites.find(params[:site_id])
  end

  def set_article
    @article = @site.articles.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :url, :status, :published_at)
  end
end
