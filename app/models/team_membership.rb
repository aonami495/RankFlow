# frozen_string_literal: true

class TeamMembership < ApplicationRecord
  belongs_to :site
  belongs_to :user
  belongs_to :invited_by, class_name: "User", optional: true

  ROLES = %w[owner editor viewer].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :site_id, message: "is already a team member" }

  scope :owners, -> { where(role: "owner") }
  scope :editors, -> { where(role: "editor") }
  scope :viewers, -> { where(role: "viewer") }

  def owner?
    role == "owner"
  end

  def editor?
    role == "editor"
  end

  def viewer?
    role == "viewer"
  end

  def can_edit?
    owner? || editor?
  end

  def can_manage_team?
    owner?
  end

  def role_label
    case role
    when "owner" then "オーナー"
    when "editor" then "編集者"
    when "viewer" then "閲覧者"
    else role
    end
  end
end
