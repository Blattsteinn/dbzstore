class RemoveDescriptionFromProduct < ActiveRecord::Migration[8.1]
  def change
    remove_column :products, :description, :text
    remove_column :products, :italian_description, :text
  end
end
