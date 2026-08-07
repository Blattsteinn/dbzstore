class AddPercentageToDiscount < ActiveRecord::Migration[8.1]
  def change
    add_column :discounts, :percentage, :integer, null: false, default: 0
  end
end
