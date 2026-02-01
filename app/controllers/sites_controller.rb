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
      redirect_to sites_path, alert: "You have reached the maximum number of sites for your plan."
      return
    end
    @site = current_user.sites.build
  end

  def create
    unless current_user.can_add_site?
      redirect_to sites_path, alert: "You have reached the maximum number of sites for your plan."
      return
    end

    @site = current_user.sites.build(site_params)

    if @site.save
      redirect_to @site, notice: "Site was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: "Site was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site.destroy
    redirect_to sites_path, notice: "Site was successfully deleted."
  end

  private

  def set_site
    @site = current_user.sites.find(params[:id])
  end

  def site_params
    params.require(:site).permit(:name, :url, :description)
  end
end
