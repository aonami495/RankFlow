# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :sites, dependent: :destroy
  has_many :alerts, dependent: :destroy
  has_many :team_memberships, dependent: :destroy
  has_many :shared_sites, through: :team_memberships, source: :site
  has_many :comments, dependent: :destroy

  validates :name, presence: true
  validates :plan, presence: true, inclusion: { in: %w[free basic pro] }

  PLAN_LIMITS = {
    "free" => { sites: 1, keywords_per_site: 5 },
    "basic" => { sites: 3, keywords_per_site: 30 },
    "pro" => { sites: 10, keywords_per_site: 100 }
  }.freeze

  def max_sites
    PLAN_LIMITS.dig(plan, :sites) || 1
  end

  def max_keywords_per_site
    PLAN_LIMITS.dig(plan, :keywords_per_site) || 5
  end

  def can_add_site?
    sites.count < max_sites
  end

  def can_add_keyword?(site)
    site.keywords.count < max_keywords_per_site
  end

  def accessible_sites
    Site.left_joins(:team_memberships)
        .where("sites.user_id = ? OR team_memberships.user_id = ?", id, id)
        .distinct
  end

  def role_for_site(site)
    return :owner if site.user_id == id

    membership = team_memberships.find_by(site: site)
    membership&.role&.to_sym
  end

  def can_edit_site?(site)
    role = role_for_site(site)
    %i[owner editor].include?(role)
  end

  def can_view_site?(site)
    role_for_site(site).present?
  end
end
