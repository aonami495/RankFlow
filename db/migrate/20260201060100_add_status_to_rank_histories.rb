class AddStatusToRankHistories < ActiveRecord::Migration[7.2]
  def change
    add_column :rank_histories, :status, :string, null: false, default: "success"
    add_column :rank_histories, :error_message, :text

    add_index :rank_histories, :status
  end
end
