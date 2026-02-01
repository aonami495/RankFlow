class CreateCompetitors < ActiveRecord::Migration[7.2]
  def change
    create_table :competitors do |t|
      t.references :site, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.text :notes

      t.timestamps
    end

    add_index :competitors, [:site_id, :url], unique: true
  end
end
