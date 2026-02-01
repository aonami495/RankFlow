class CreateCompetitorRankHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :competitor_rank_histories do |t|
      t.references :competitor, null: false, foreign_key: true
      t.references :keyword, null: false, foreign_key: true
      t.integer :rank, null: false
      t.date :checked_at, null: false

      t.timestamps
    end

    add_index :competitor_rank_histories, [:competitor_id, :keyword_id, :checked_at],
              unique: true, name: "idx_competitor_rank_unique"
  end
end
