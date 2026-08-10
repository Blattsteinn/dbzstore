class GeocodeVisitJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    visit = Ahoy::Visit.find_by(id: visit_id)
    return unless visit
    return if visit.ip.blank? || visit.ip == "127.0.0.1" || visit.ip == "::1"

    result = Geocoder.search(visit.ip).first
    return unless result

    visit.update_columns(
      country: result.country,
      city: result.city,
      region: result.respond_to?(:region) ? result.region : nil,
      latitude: result.try(:latitude),
      longitude: result.try(:longitude)
    )
  rescue => e
    Rails.logger.warn "[Ahoy] Geocode failed for IP #{visit&.ip}: #{e.message}"
  end
end