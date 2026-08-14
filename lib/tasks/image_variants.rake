namespace :images do
  desc "Preprocess all image variants (600 thumbnail, 1200 display, 1600 hero) for every product image"
  task backfill_variants: :environment do
    count = ProductImage.count
    puts "Preprocessing variants for #{count} product image(s)..."

    ProductImage.find_each do |image|
      ProcessImageVariantsJob.perform_now(image.id)
    end

    puts "Done."
  end
end
