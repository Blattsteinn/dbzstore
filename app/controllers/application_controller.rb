class ApplicationController < ActionController::Base
  include Pagy::Method
  
  # Shifting away from User Based as site will function as userless.
  # before_action :authenticate_user!

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :admin_page?

  private
  def admin_page?
    @admin_page == true
  end

  def authenticate_admin!
    authenticate_user!
    if current_user.admin?
      @admin_page = true
    else
      redirect_to root_path, alert: "You must be an admin"
    end
  end

  def honeypot_check
    if params[:contact_me_by_fax_only].present?
      head :ok
      return
    end
  end

end
