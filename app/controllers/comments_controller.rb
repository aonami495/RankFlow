# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_commentable
  before_action :authorize_access!
  before_action :set_comment, only: %i[edit update destroy]
  before_action :authorize_edit!, only: %i[edit update destroy]

  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to commentable_path, notice: "コメントを追加しました"
    else
      flash[:alert] = @comment.errors.full_messages.join(", ")
      redirect_to commentable_path
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      redirect_to commentable_path, notice: "コメントを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    redirect_to commentable_path, notice: "コメントを削除しました"
  end

  private

  def set_commentable
    if params[:keyword_id]
      @commentable = Keyword.find(params[:keyword_id])
      @site = @commentable.site
    elsif params[:site_id]
      @commentable = Site.find(params[:site_id])
      @site = @commentable
    else
      redirect_to root_path, alert: "コメント対象が見つかりません"
    end
  end

  def authorize_access!
    is_owner = @site.user_id == current_user.id
    is_member = @site.team_memberships.exists?(user: current_user)

    unless is_owner || is_member
      redirect_to sites_path, alert: "アクセス権限がありません"
    end
  end

  def set_comment
    @comment = @commentable.comments.find(params[:id])
  end

  def authorize_edit!
    unless @comment.editable_by?(current_user)
      redirect_to commentable_path, alert: "このコメントを編集する権限がありません"
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def commentable_path
    case @commentable
    when Keyword
      site_keyword_path(@site, @commentable)
    when Site
      site_path(@commentable)
    else
      root_path
    end
  end
end
