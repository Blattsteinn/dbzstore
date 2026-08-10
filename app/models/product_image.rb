class ProductImage < ApplicationRecord
    belongs_to :product, touch: true
    has_one_attached :image
  
    validates :image, presence: true
    after_create_commit :process_variants, if: -> { image.attached? }

    def display
      return unless image.attached?

      image.variant(
        resize_to_limit: [1200, 1200],
        format: :webp,
        saver: { quality: 80 }
      )
  end
  private

  def process_variants
    ProcessImageVariantsJob.perform_later(id)
  end
  
end
