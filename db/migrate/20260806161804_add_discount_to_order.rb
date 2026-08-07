class AddDiscountToOrder < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :discount, foreign_key: true
    add_column :orders, :discount_percentage, :integer
  end
end
