class AddIndexToLocalizedDescriptions < ActiveRecord::Migration[8.1]
  def change
        add_index :localized_descriptions,
      [:product_id, :language_id], unique: true
  end
end
