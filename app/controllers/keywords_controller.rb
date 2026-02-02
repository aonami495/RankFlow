# frozen_string_literal: true

class KeywordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site
  before_action :set_keyword, only: [:show, :edit, :update, :destroy]

  def show
    @rank_history = @keyword.rank_history_30days
  end

  def new
    unless current_user.can_add_keyword?(@site)
      redirect_to site_path(@site), alert: t("keywords.plan_limit_reached")
      return
    end
    @keyword = @site.keywords.build
  end

  def create
    unless current_user.can_add_keyword?(@site)
      redirect_to site_path(@site), alert: t("keywords.plan_limit_reached")
      return
    end

    @keyword = @site.keywords.build(keyword_params)

    if @keyword.save
      redirect_to site_path(@site), notice: t("keywords.created_success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @keyword.update(keyword_params)
      redirect_to site_path(@site), notice: t("keywords.updated_success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @keyword.destroy
    redirect_to site_path(@site), notice: t("keywords.deleted_success")
  end

  private

  def set_site
    @site = current_user.sites.find(params[:site_id])
  end

  def set_keyword
    @keyword = @site.keywords.find(params[:id])
  end

  def keyword_params
    params.require(:keyword).permit(:word, :target_url, :article_id)
  end
end
