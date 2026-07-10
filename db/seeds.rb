# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb


User.create!(email: "admin@admin", password: "password", admin: true)


# ── Test product ──────────────────────────────────────────────
product = Product.find_or_create_by!(title: "Test - 8,000 Dragon Stones (Global)") do |p|
  p.description  = "A test account with 8,000 Dragon Stones for development."
  p.visibility   = "live"
  p.payment_type = "single_payment"
  p.deliverables = "static"
end

Variant.find_or_create_by!(product: product, title: "iOS") do |v|
  v.price       = 899   # cents → €8.99
  v.stock       = 10
  v.description = "iOS version"
end

Variant.find_or_create_by!(product: product, title: "Android") do |v|
  v.price       = 599   # cents → €5.99
  v.stock       = 14
  v.description = "Android version"
end

Game.create!(name: "dokkan", official_name: "DBZ Dokkan Battle")
Game.create!(name: "optc",   official_name: "One Piece Treasure Cruise (OPTC)")
Game.create!(name: "legends",   official_name: "DRAGON BALL LEGENDS")

# puts "Test product ready: #{product.title}"
# puts "  Variants: #{product.variants.pluck(:title).join(', ')}"
# puts "  Images:   #{product.product_images.count}"
# puts "  Seeding complete!"