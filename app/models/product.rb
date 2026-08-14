class Product < ApplicationRecord
    scope :visible, -> { where(visibility: "live") }

    scope :dokkan, -> {where(game_name: "dokkan")}
    scope :legends, -> {where(game_name: "legends")}

    has_many :product_images, -> { order(priority: :asc) }, dependent: :destroy
    accepts_nested_attributes_for :product_images, allow_destroy: true,
        reject_if: ->(attrs) {  attrs["image"].blank? }

    has_many :order_items, dependent: :nullify

    has_many :variants, dependent: :destroy
    accepts_nested_attributes_for :variants, allow_destroy: true, reject_if: :all_blank

    has_many :localized_descriptions, dependent: :destroy
    accepts_nested_attributes_for :localized_descriptions, allow_destroy: true, 
        reject_if: ->(attrs) { attrs["description"].blank? }
    

    validates :deliverables,    presence: true
    validates :payment_type,    presence: true
    validates :title,           presence: true
    validates :visibility,      presence: true

    def primary_image
        product_images.first&.image
    end

    def thumbnail
      return unless primary_image.attached?

      primary_image.variant(
          resize_to_limit: [600, 600],
          format: :webp,
          saver: { quality: 75 }
      )
    end

    def hero_image
      return unless primary_image&.attached?

      primary_image.variant(
          resize_to_limit: [1600, 1600],
          format: :webp,
          saver: { quality: 80 }
      )
    end
end
