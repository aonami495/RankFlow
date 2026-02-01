# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.2]
  def change
    # Users table already exists with correct structure
    # This migration is kept for Devise compatibility
  end
end
