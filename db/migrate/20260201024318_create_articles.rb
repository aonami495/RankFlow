class CreateArticles < ActiveRecord::Migration[7.2]
  def change
    create_table :articles do |t|
      t.references :site, null: false, foreign_key: true
      t.string :title
      t.string :url
      t.string :status
      t.datetime :published_at

      t.timestamps
    end
  end
end
