# frozen_string_literal: true

class CompetitorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site
  before_action :set_competitor, only: [:edit, :update, :destroy]
  before_action :set_competitor_with_histories, only: [:show]

  def index
    @competitors = @site.competitors.includes(:competitor_rank_histories)
    @keywords = @site.keywords.includes(:rank_histories)
  end

  def show
    @keywords = @site.keywords.includes(:rank_histories)
    @rank_comparison = build_rank_comparison
  end

  def new
    @competitor = @site.competitors.build
  end

  def create
    @competitor = @site.competitors.build(competitor_params)

    if @competitor.save
      redirect_to site_competitors_path(@site), notice: "Competitor added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @competitor.update(competitor_params)
      redirect_to site_competitors_path(@site), notice: "Competitor updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @competitor.destroy
    redirect_to site_competitors_path(@site), notice: "Competitor removed."
  end

  private

  def set_site
    @site = current_user.sites.find(params[:site_id])
  end

  def set_competitor
    @competitor = @site.competitors.find(params[:id])
  end

  def set_competitor_with_histories
    @competitor = @site.competitors.includes(:competitor_rank_histories).find(params[:id])
  end

  def competitor_params
    params.require(:competitor).permit(:name, :url, :notes)
  end

  def build_rank_comparison
    @keywords.map do |keyword|
      my_rank = keyword.current_rank
      competitor_rank = @competitor.current_rank_for(keyword)
      my_change = keyword.rank_change
      competitor_change = @competitor.rank_change_for(keyword)

      {
        keyword: keyword,
        my_rank: my_rank,
        competitor_rank: competitor_rank,
        difference: calculate_difference(my_rank, competitor_rank),
        my_change: my_change,
        competitor_change: competitor_change
      }
    end
  end

  def calculate_difference(my_rank, competitor_rank)
    return nil unless my_rank && competitor_rank
    return nil if my_rank > 100 || competitor_rank > 100

    competitor_rank - my_rank
  end
end
