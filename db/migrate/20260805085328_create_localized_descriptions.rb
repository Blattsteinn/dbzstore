class CreateLocalizedDescriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :localized_descriptions do |t|
      t.timestamps
      t.text :description

      t.references :languages, null: false, foreign_key: true
      t.references :products, null: false, foreign_key: true
    end
  end
end
