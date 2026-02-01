class CreateAspConnections < ActiveRecord::Migration[7.2]
  def change
    create_table :asp_connections do |t|
      t.references :site, null: false, foreign_key: true
      t.string :asp_name, null: false
      t.string :api_key_encrypted
      t.string :api_secret_encrypted
      t.string :status, default: "pending", null: false
      t.datetime :last_synced_at
      t.text :sync_error

      t.timestamps
    end

    add_index :asp_connections, [:site_id, :asp_name], unique: true
  end
end
