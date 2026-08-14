class ProcessImageVariantsJob < ApplicationJob
  queue_as :default

  def perform(product_image_id)
    image = ProductImage.find_by(id: product_image_id)
    return unless image&.image&.attached?

    image.thumbnail.processed   # 600×600 webp (index thumbnail)
    image.display.processed     # 1200×1200 webp (show gallery)
    image.hero.processed        # 1600×1600 webp (hero / LCP)
  end
end