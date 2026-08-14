class AddStartedAtIndexToAhoyVisits < ActiveRecord::Migration[8.1]
  def change
    # Dashboard 7-day visitor count + visitors page sort by started_at;
    # the (visitor_token, started_at) composite can't serve started_at-only predicates.
    add_index :ahoy_visits, :started_at
  end
end
