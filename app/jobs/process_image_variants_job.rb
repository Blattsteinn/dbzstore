class ProcessImageVariantsJob < ApplicationJob
  queue_as :default

  def perform(product_image_id)
    image = ProductImage.find_by(id: product_image_id)
    return unless image&.image&.attached?

    image.display.processed      # 1200×1200 webp (show gallery)
    image.image.variant(resize_to_limit: [600, 600], format: :webp,
                        saver: { quality: 75 }).processed  # index thumbnail
  end
end