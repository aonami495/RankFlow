class CreateAlerts < ActiveRecord::Migration[7.2]
  def change
    create_table :alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :alertable, polymorphic: true, null: false
      t.string :alert_type, null: false
      t.text :message
      t.boolean :read, default: false, null: false
      t.datetime :triggered_at, null: false

      t.timestamps
    end

    add_index :alerts, [:user_id, :read, :triggered_at]
  end
end
