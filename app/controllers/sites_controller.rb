# frozen_string_literal: true

class SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, only: [:show, :edit, :update, :destroy]

  def index
    @sites = current_user.sites.includes(:keywords).order(created_at: :desc)
  end

  def show
    @keywords = @site.keywords.includes(:rank_histories).order(created_at: :desc)
  end

  def new
    unless current_user.can_add_site?
      redirect_to sites_path, alert: t("sites.plan_limit_reached")
      return
    end
    @site = current_user.sites.build
  end

  def create
    unless current_user.can_add_site?
      redirect_to sites_path, alert: t("sites.plan_limit_reached")
      return
    end

    @site = current_user.sites.build(site_params)

    if @site.save
      redirect_to @site, notice: t("sites.created_success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: t("sites.updated_success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site.destroy
    redirect_to sites_path, notice: t("sites.deleted_success")
  end

  private

  def set_site
    @site = current_user.sites.find(params[:id])
  end

  def site_params
    params.require(:site).permit(:name, :url, :description)
  end
end
