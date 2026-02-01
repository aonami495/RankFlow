# frozen_string_literal: true

class KeywordResearchController < ApplicationController
  before_action :authenticate_user!

  def index
    @sites = current_user.sites
    @current_site = @sites.find_by(id: params[:site_id]) || @sites.first
  end

  def search
    @query = params[:query]&.strip
    @site = current_user.sites.find_by(id: params[:site_id])

    if @query.blank?
      render json: { error: "Please enter a keyword" }, status: :unprocessable_entity
      return
    end

    @results = KeywordResearchService.search(@query)

    respond_to do |format|
      format.html { render partial: "results", locals: { results: @results, site: @site } }
      format.json { render json: @results }
    end
  end
end
