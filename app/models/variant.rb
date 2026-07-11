class Variant < ApplicationRecord
    belongs_to :product
    has_many :order_items, dependent: :nullify

    validates :stock, numericality: true
end
