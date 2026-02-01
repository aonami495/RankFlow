# frozen_string_literal: true

class TeamMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site
  before_action :authorize_team_management!
  before_action :set_team_membership, only: %i[update destroy]

  def index
    @team_memberships = @site.team_memberships.includes(:user, :invited_by).order(:created_at)
  end

  def new
    @team_membership = @site.team_memberships.new
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user.nil?
      flash[:alert] = "指定されたメールアドレスのユーザーが見つかりません"
      redirect_to site_team_memberships_path(@site) and return
    end

    if @site.team_memberships.exists?(user: user)
      flash[:alert] = "このユーザーは既にチームメンバーです"
      redirect_to site_team_memberships_path(@site) and return
    end

    @team_membership = @site.team_memberships.new(
      user: user,
      role: team_membership_params[:role],
      invited_by: current_user
    )

    if @team_membership.save
      redirect_to site_team_memberships_path(@site), notice: "#{user.name}さんをチームに追加しました"
    else
      flash[:alert] = @team_membership.errors.full_messages.join(", ")
      redirect_to site_team_memberships_path(@site)
    end
  end

  def update
    if @team_membership.owner? && team_membership_params[:role] != "owner"
      owners_count = @site.team_memberships.owners.count
      if owners_count <= 1
        flash[:alert] = "サイトには最低1人のオーナーが必要です"
        redirect_to site_team_memberships_path(@site) and return
      end
    end

    if @team_membership.update(team_membership_params)
      redirect_to site_team_memberships_path(@site), notice: "権限を更新しました"
    else
      flash[:alert] = @team_membership.errors.full_messages.join(", ")
      redirect_to site_team_memberships_path(@site)
    end
  end

  def destroy
    if @team_membership.owner?
      owners_count = @site.team_memberships.owners.count
      if owners_count <= 1
        flash[:alert] = "サイトには最低1人のオーナーが必要です"
        redirect_to site_team_memberships_path(@site) and return
      end
    end

    user_name = @team_membership.user.name
    @team_membership.destroy
    redirect_to site_team_memberships_path(@site), notice: "#{user_name}さんをチームから削除しました"
  end

  private

  def set_site
    @site = current_user.sites.find_by(id: params[:site_id]) ||
            current_user.shared_sites.find_by(id: params[:site_id])

    unless @site
      redirect_to sites_path, alert: "サイトが見つかりません" and return
    end
  end

  def authorize_team_management!
    membership = @site.team_memberships.find_by(user: current_user)
    is_owner = @site.user_id == current_user.id

    unless is_owner || membership&.can_manage_team?
      redirect_to site_path(@site), alert: "チーム管理の権限がありません"
    end
  end

  def set_team_membership
    @team_membership = @site.team_memberships.find(params[:id])
  end

  def team_membership_params
    params.require(:team_membership).permit(:role)
  end
end
