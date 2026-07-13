class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true

  after_create :geocode_ip, unless: -> { ip.blank? || ip == "127.0.0.1" || ip == "::1" }

  private

  def geocode_ip
    result = Geocoder.search(ip).first
    return unless result

    update_columns(
      country: result.country,
      city: result.city,
      region: result.respond_to?(:region) ? result.region : nil,
      latitude: result.try(:latitude),
      longitude: result.try(:longitude)
    )
  rescue => e
    Rails.logger.warn "[Ahoy] Geocode failed for IP #{ip}: #{e.message}"
  end
end
