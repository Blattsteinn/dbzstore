class Order < ApplicationRecord

    before_validation :generate_public_id, on: :create
    validates :status, inclusion: { in: %w[pending paid processing delivered cancelled refunded] }
    validates :email, presence: true

    # after_create_commit { PurchaseSuccess.successful_purchase(self).deliver_later }

    belongs_to :user, optional: true
    has_many :order_items, dependent: :destroy
    has_many :feedbacks, dependent: :destroy
    has_many :support_messages, dependent: :destroy

    belongs_to :discount, optional: true

    def paid?
        status == "paid"
    end

    def generate_public_id
        self.public_id ||= SecureRandom.alphanumeric(20).upcase
    end
end
