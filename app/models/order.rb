class Order < ApplicationRecord

    before_validation :generate_public_id, on: :create
    validates :status, inclusion: { in: %w[pending paid processing delivered cancelled refunded] }

    # after_create_commit { PurchaseSuccess.successful_purchase(self).deliver_later }

    belongs_to :user, optional: true
    has_many :order_items, dependent: :destroy
    has_many :feedbacks, dependent: :destroy
    has_many :support_messages, dependent: :destroy

    def restore_stock!
        ActiveRecord::Base.transaction do
            order_items.includes(:variant).find_each do |item|
            Variant.where(id: item.variant_id).update_counters(item.variant_id, stock: item.quantity)
            end
        end
    end

    def paid?
        status == "paid"
    end

    def generate_public_id
        self.public_id ||= SecureRandom.alphanumeric(20).upcase
    end
end
