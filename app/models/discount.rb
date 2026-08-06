class Discount < ApplicationRecord
    validates :code, presence: true

    validates :amount, presence: true, numericality: {
        only_integer: true,
        greater_than_or_equal_to: 0}

    validates :remaining, presence: true, numericality: {
        only_integer: true,
        greater_than_or_equal_to: 0}

  def available?
    remaining.positive?
  end

  def redeem!
    return false unless available?
    update!(remaining: remaining - 1s)
  end
end
