class LocalizedDescription < ApplicationRecord
    belongs_to :product, touch: true
    belongs_to :language

    validates :description, presence: true

    # Unique on product & language
    validates :language, uniqueness: { scope: :product }
end
