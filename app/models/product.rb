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
      product_images.first&.thumbnail
    end

    def hero_image
      product_images.first&.hero
    end
end
