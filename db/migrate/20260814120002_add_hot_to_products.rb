class AddHotToProducts < ActiveRecord::Migration[8.1]
  def change
    # "Hot" tag shown on the product card in /:game/products when true.
    add_column :products, :hot, :boolean, default: false, null: false
  end
end
