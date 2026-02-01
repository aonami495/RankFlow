class CreateArticleRevenues < ActiveRecord::Migration[7.2]
  def change
    create_table :article_revenues do |t|
      t.references :article, null: false, foreign_key: true
      t.string :asp_name
      t.decimal :amount
      t.date :month

      t.timestamps
    end
  end
end
