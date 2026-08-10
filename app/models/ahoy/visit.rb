class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true


  after_create_commit :geocode_ip_later, unless: -> { ip.blank? || ip == "127.0.0.1" || ip == "::1" }

  private 

  def geocode_ip_later
    GeocodeVisitJob.perform_later(id)
  end
end
