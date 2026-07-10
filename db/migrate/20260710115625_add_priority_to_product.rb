class AddPriorityToProduct < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :priority, :integer, default: 1
  end
end
