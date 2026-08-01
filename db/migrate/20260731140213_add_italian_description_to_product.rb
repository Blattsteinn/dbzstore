class AddItalianDescriptionToProduct < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :italian_description, :text
  end
end
