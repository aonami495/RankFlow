# frozen_string_literal: true

class RevenuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_revenue, only: [:edit, :update, :destroy]

  def index
    @sites = current_user.sites
    @current_site = @sites.find_by(id: params[:site_id]) || @sites.first
    @current_month = params[:month].present? ? Date.parse(params[:month]) : Date.current.beginning_of_month

    if @current_site
      @revenues = @current_site.revenues.by_month(@current_month).order(:asp_name)
      @monthly_totals = @current_site.revenues.monthly_totals(months: 6)
      @total_revenue = @revenues.sum(:amount)
    else
      @revenues = []
      @monthly_totals = {}
      @total_revenue = 0
    end
  end

  def new
    @sites = current_user.sites
    @revenue = Revenue.new(month: Date.current.beginning_of_month)
  end

  def create
    @revenue = Revenue.new(revenue_params)

    if @revenue.site&.user != current_user
      redirect_to revenues_path, alert: "Invalid site selected."
      return
    end

    if @revenue.save
      redirect_to revenues_path(site_id: @revenue.site_id, month: @revenue.month),
                  notice: "Revenue was successfully added."
    else
      @sites = current_user.sites
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sites = current_user.sites
  end

  def update
    # Verify site ownership if site_id is being changed
    if revenue_params[:site_id].present? && revenue_params[:site_id].to_i != @revenue.site_id
      new_site = current_user.sites.find_by(id: revenue_params[:site_id])
      unless new_site
        redirect_to revenues_path, alert: "Invalid site selected."
        return
      end
    end

    if @revenue.update(revenue_params)
      redirect_to revenues_path(site_id: @revenue.site_id, month: @revenue.month),
                  notice: "Revenue was successfully updated."
    else
      @sites = current_user.sites
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    site_id = @revenue.site_id
    month = @revenue.month
    @revenue.destroy
    redirect_to revenues_path(site_id: site_id, month: month),
                notice: "Revenue was successfully deleted."
  end

  private

  def set_revenue
    @revenue = Revenue.joins(:site).where(sites: { user_id: current_user.id }).find(params[:id])
  end

  def revenue_params
    params.require(:revenue).permit(:site_id, :asp_name, :amount, :month)
  end
end
