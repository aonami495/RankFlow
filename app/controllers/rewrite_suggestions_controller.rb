# frozen_string_literal: true

class RewriteSuggestionsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Efficient query with proper includes to avoid N+1
    @articles = Article.joins(:site)
                       .where(sites: { user_id: current_user.id })
                       .where.not(status: "archived")
                       .includes(keywords: :rank_histories)
                       .includes(:article_revenues)
                       .select { |a| a.keywords.any? }
                       .sort_by { |a| -a.rewrite_priority_score_cached }
                       .first(20)
  end
end
