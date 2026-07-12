class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true

  after_create :geocode_country!, unless: -> { country.present? }

  private

  def geocode_country!
    return if ip.blank? || ip == "127.0.0.1" || ip == "::1"

    location = Geocoder.search(ip).first
    update_column(:country, location.country) if location&.country.present?
  rescue => e
    Rails.logger.warn "Geocode failed for IP #{ip}: #{e.message}"
  end
end
