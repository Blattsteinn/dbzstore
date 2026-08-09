module ApplicationHelper
  # Games for the nav dropdown (memoized per request).
  def navigation_games
    @navigation_games ||= Game.order(:name).all
  end

  # Active-state helper for nav links. Pass controller name(s) and optional
  # action name(s); with no actions, any action in the controller matches.
  def nav_active?(controllers, actions = [])
    controllers = Array(controllers).map(&:to_s)
    actions = Array(actions).map(&:to_s)
    controllers.include?(controller_name) && (actions.empty? || actions.include?(action_name))
  end
end
