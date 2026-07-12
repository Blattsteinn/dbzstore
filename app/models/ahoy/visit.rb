class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true

  after_create :geocode_country!, unless: -> { country.present? }

  private

  def geocode_country!
    return if ip.blank? || ip == "127.0.0.1" || ip == "::1"

    db = MaxMind::DB.new(Rails.root.join("vendor", "GeoLite2-Country.mmdb").to_s)
    result = db.lookup(ip)
    update_column(:country, result.dig("country", "iso_code")) if result
  rescue => e
    Rails.logger.warn "Geocode failed for IP #{ip}: #{e.message}"
  end

end
