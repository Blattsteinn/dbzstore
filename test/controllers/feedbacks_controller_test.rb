require "test_helper"

class FeedbacksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @order = Order.create!(email: "buyer@example.com", status: "paid")
    @feedback = Feedback.create!(order: @order, feedback: "Really happy with the account!", rating: 5)
  end

  def sign_in_as_admin
    sign_in User.create!(email: "admin@example.com", password: "password123", admin: true)
  end

  def sign_in_as_user
    sign_in User.create!(email: "user@example.com", password: "password123")
  end

  # ---------------------------------------------------------------
  # GET /feedbacks (index) — public
  # ---------------------------------------------------------------

  test "index is publicly accessible" do
    get feedbacks_url
    assert_response :ok
  end

  test "index lists feedbacks newest first" do
    Feedback.delete_all
    older_order = Order.create!(email: "older@example.com", status: "paid")
    newer_order = Order.create!(email: "newer@example.com", status: "paid")

    Feedback.create!(order: older_order, feedback: "Older feedback here", rating: 4, created_at: 2.days.ago)
    Feedback.create!(order: newer_order, feedback: "Newer feedback here", rating: 5, created_at: 1.day.ago)

    get feedbacks_url

    assert_response :ok
    assert_equal [ "Newer feedback here", "Older feedback here" ],
                 css_select(".feedback-body").map { |node| node.text.strip }
  end

  # ---------------------------------------------------------------
  # GET /feedbacks/new (new) — public
  # ---------------------------------------------------------------

  test "new is publicly accessible" do
    get new_feedback_url
    assert_response :ok
  end

  # ---------------------------------------------------------------
  # POST /feedbacks (create) — public
  # ---------------------------------------------------------------

  test "create saves feedback linked to the order public_id" do
    order = Order.create!(email: "fresh@example.com", status: "paid")

    assert_difference "Feedback.count", 1 do
      post feedbacks_url, params: {
        feedback: { public_id: order.public_id, rating: 5, feedback: "Great service overall!" }
      }
    end

    assert_equal order.id, Feedback.last.order_id
    assert_equal 5, Feedback.last.rating
    assert_redirected_to feedbacks_url
  end

  test "create with an unknown public_id fails validation" do
    assert_no_difference "Feedback.count" do
      post feedbacks_url, params: {
        feedback: { public_id: "DOES_NOT_EXIST", rating: 5, feedback: "Great service overall!" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with an out-of-range rating fails validation" do
    assert_no_difference "Feedback.count" do
      post feedbacks_url, params: {
        feedback: { public_id: @order.public_id, rating: 6, feedback: "Great service overall!" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with duplicate feedback for the same order fails validation" do
    assert_no_difference "Feedback.count" do
      post feedbacks_url, params: {
        feedback: { public_id: @order.public_id, rating: 4, feedback: "Another review for the same order." }
      }
    end

    assert_response :unprocessable_entity
  end

  test "honeypot field blocks create without saving" do
    assert_no_difference "Feedback.count" do
      post feedbacks_url, params: {
        contact_me_by_fax_only: "spam",
        feedback: { public_id: @order.public_id, rating: 5, feedback: "Great service overall!" }
      }
    end

    assert_response :ok
  end

  # ---------------------------------------------------------------
  # GET /feedbacks/:id/edit (edit) — admin only
  # ---------------------------------------------------------------

  test "edit redirects unauthenticated visitors to sign in" do
    get edit_feedback_url(@feedback)
    assert_redirected_to new_user_session_path
  end

  test "edit blocks non-admin users" do
    sign_in_as_user
    get edit_feedback_url(@feedback)
    assert_redirected_to root_path
    assert_equal "You must be an admin", flash[:alert]
  end

  test "admin can access the edit form" do
    sign_in_as_admin
    get edit_feedback_url(@feedback)
    assert_response :ok
  end

  # ---------------------------------------------------------------
  # PATCH /feedbacks/:id (update) — admin only
  # ---------------------------------------------------------------

  test "update redirects unauthenticated visitors to sign in" do
    patch feedback_url(@feedback), params: { feedback: { rating: 4, feedback: "Updated review text here!" } }
    assert_redirected_to new_user_session_path
    assert_equal 5, @feedback.reload.rating
  end

  test "admin can update feedback" do
    sign_in_as_admin
    patch feedback_url(@feedback), params: { feedback: { rating: 4, feedback: "Updated review text here!" } }

    assert_redirected_to dashboard_feedbacks_url
    assert_equal 4, @feedback.reload.rating
    assert_equal "Updated review text here!", @feedback.reload.feedback
  end

  # ---------------------------------------------------------------
  # DELETE /feedbacks/:id (destroy) — admin only
  # ---------------------------------------------------------------

  test "destroy redirects unauthenticated visitors to sign in" do
    assert_no_difference "Feedback.count" do
      delete feedback_url(@feedback)
    end
    assert_redirected_to new_user_session_path
  end

  test "admin can destroy feedback" do
    sign_in_as_admin

    assert_difference "Feedback.count", -1 do
      delete feedback_url(@feedback)
    end

    assert_redirected_to dashboard_feedbacks_url
  end
end
