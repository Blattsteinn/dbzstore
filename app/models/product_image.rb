class ProductImage < ApplicationRecord
    belongs_to :product, touch: true
    has_one_attached :image

    validates :image, presence: true
    after_create_commit :process_variants, if: -> { image.attached? }

    THUMB_OPTS   = { resize_to_limit: [600, 600],   format: :webp, saver: { quality: 75 } }.freeze
    DISPLAY_OPTS = { resize_to_limit: [1200, 1200], format: :webp, saver: { quality: 80 } }.freeze
    HERO_OPTS    = { resize_to_limit: [1600, 1600], format: :webp, saver: { quality: 80 } }.freeze

    def thumbnail
      return unless image.attached?

      image.variant(**THUMB_OPTS)
    end

    def display
      return unless image.attached?

      image.variant(**DISPLAY_OPTS)
    end

    def hero
      return unless image.attached?

      image.variant(**HERO_OPTS)
    end

    private

    def process_variants
      ProcessImageVariantsJob.perform_later(id)
    end
end
