# frozen_string_literal: true

class AspConnectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site
  before_action :set_asp_connection, only: [:edit, :update, :destroy, :sync]

  def index
    @asp_connections = @site.asp_connections
    @available_asps = AspConnection::ASP_CONFIGS.reject do |asp_name, _|
      @asp_connections.exists?(asp_name: asp_name)
    end
  end

  def new
    @asp_connection = @site.asp_connections.build(asp_name: params[:asp_name])

    unless AspConnection::ASP_CONFIGS.key?(@asp_connection.asp_name)
      redirect_to site_asp_connections_path(@site), alert: "Invalid ASP selected."
    end
  end

  def create
    @asp_connection = @site.asp_connections.build(asp_connection_params)

    if @asp_connection.save
      if @asp_connection.supports_auto_sync? && @asp_connection.api_key_encrypted.present?
        @asp_connection.sync!
      end
      redirect_to site_asp_connections_path(@site), notice: "#{@asp_connection.display_name} connection added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @asp_connection.update(asp_connection_params)
      redirect_to site_asp_connections_path(@site), notice: "#{@asp_connection.display_name} connection updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @asp_connection.destroy
    redirect_to site_asp_connections_path(@site), notice: "ASP connection removed."
  end

  def sync
    if @asp_connection.sync!
      redirect_to site_asp_connections_path(@site), notice: "Successfully synced #{@asp_connection.display_name} data."
    else
      redirect_to site_asp_connections_path(@site), alert: "Sync failed: #{@asp_connection.sync_error}"
    end
  end

  private

  def set_site
    @site = current_user.sites.find(params[:site_id])
  end

  def set_asp_connection
    @asp_connection = @site.asp_connections.find(params[:id])
  end

  def asp_connection_params
    params.require(:asp_connection).permit(:asp_name, :api_key_encrypted, :api_secret_encrypted, :status)
  end
end
