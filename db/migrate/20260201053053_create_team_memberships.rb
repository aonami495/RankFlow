class CreateTeamMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :team_memberships do |t|
      t.references :site, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "viewer"
      t.integer :invited_by_id

      t.timestamps
    end

    add_index :team_memberships, [:site_id, :user_id], unique: true
    add_foreign_key :team_memberships, :users, column: :invited_by_id
  end
end
