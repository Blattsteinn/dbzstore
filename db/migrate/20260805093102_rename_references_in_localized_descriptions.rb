class RenameReferencesInLocalizedDescriptions < ActiveRecord::Migration[8.1]
  def change
    rename_column :localized_descriptions, :languages_id, :language_id
    rename_column :localized_descriptions, :products_id, :product_id
  end
end
