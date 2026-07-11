class AddPriorityIndexToProducts < ActiveRecord::Migration[8.1]
  def change
    add_index :products, :priority
  end
end
