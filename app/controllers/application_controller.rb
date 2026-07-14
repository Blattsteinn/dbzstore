class ApplicationController < ActionController::Base
  include Pagy::Method
  
  # Shifting away from User Based as site will function as userless.
  # before_action :authenticate_user!

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
  def authenticate_admin!
    authenticate_user!
    redirect_to root_path, alert: "You must be an admin" unless current_user.admin?
  end

  def honeypot_check
    if params[:contact_me_by_fax_only].present?
      head :ok
    end
  end

end
