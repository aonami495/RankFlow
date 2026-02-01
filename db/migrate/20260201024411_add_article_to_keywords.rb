# frozen_string_literal: true

class AddArticleToKeywords < ActiveRecord::Migration[7.2]
  def change
    add_reference :keywords, :article, null: true, foreign_key: true
  end
end
