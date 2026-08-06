class CreateDiscounts < ActiveRecord::Migration[8.1]
  def change
    create_table :discounts do |t|
      t.timestamps
      t.string :code, null: false
      t.integer :amount, null: false
      t.integer :remaining, null: false

      t.index :code, unique: true
    end
  end
end
