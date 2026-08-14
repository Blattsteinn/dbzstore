class AddIndexesToFeedbacks < ActiveRecord::Migration[8.1]
  def up
    # Dashboard + public feedback pagination sort by created_at (was unindexed seq scan).
    add_index :feedbacks, :created_at

    # Guard against legacy duplicates before enforcing uniqueness — past races
    # could have created more than one feedback row per order, which would make
    # the unique index below fail and abort db:prepare on deploy. Keep the
    # lowest-id row per order (matches the model's `validates :order, uniqueness: true`).
    execute(<<~SQL)
      DELETE FROM feedbacks a
      USING feedbacks b
      WHERE a.order_id = b.order_id
        AND a.id > b.id
    SQL

    # Model already validates order uniqueness; make the DB enforce it too.
    remove_index :feedbacks, name: "index_feedbacks_on_order_id"
    add_index :feedbacks, :order_id, unique: true, name: "index_feedbacks_on_order_id"
  end

  def down
    remove_index :feedbacks, name: "index_feedbacks_on_order_id"
    add_index :feedbacks, :order_id, name: "index_feedbacks_on_order_id"
    remove_index :feedbacks, :created_at
  end
end
