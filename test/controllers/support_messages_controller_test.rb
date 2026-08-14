require "test_helper"

class SupportMessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @order = Order.create!(email: "buyer@example.com")
    @message = SupportMessage.create!(
      title: "Issue with order", email: "buyer@example.com",
      message: "This is a fairly long message about my problem.", order: @order
    )
  end

  def sign_in_as_admin
    sign_in User.create!(email: "admin@example.com", password: "password123", admin: true)
  end

  def sign_in_as_user
    sign_in User.create!(email: "user@example.com", password: "password123")
  end

  # ---------------------------------------------------------------
  # GET /support_messages/new (new) — public
  # ---------------------------------------------------------------

  test "new is publicly accessible" do
    get new_support_message_url
    assert_response :ok
  end

  # ---------------------------------------------------------------
  # POST /support_messages (create) — public
  # ---------------------------------------------------------------

  test "create saves a support message linked to the order public_id" do
    assert_difference "SupportMessage.count", 1 do
      post support_messages_url, params: {
        support_message: {
          title: "My order issue", email: "buyer@example.com",
          message: "I never received my account after paying.", public_id: @order.public_id
        }
      }
    end

    message = SupportMessage.last
    assert_equal @order.id, message.order_id
    assert_equal "open", message.status
    assert_redirected_to new_support_message_url
  end

  test "create with an unknown public_id fails validation" do
    assert_no_difference "SupportMessage.count" do
      post support_messages_url, params: {
        support_message: {
          title: "My order issue", email: "buyer@example.com",
          message: "I never received my account after paying.", public_id: "DOES_NOT_EXIST"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create without a public_id fails validation" do
    assert_no_difference "SupportMessage.count" do
      post support_messages_url, params: {
        support_message: {
          title: "My order issue", email: "buyer@example.com",
          message: "I never received my account after paying."
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "honeypot field blocks create without saving" do
    assert_no_difference "SupportMessage.count" do
      post support_messages_url, params: {
        contact_me_by_fax_only: "spam",
        support_message: {
          title: "My order issue", email: "buyer@example.com",
          message: "I never received my account after paying.", public_id: @order.public_id
        }
      }
    end

    assert_response :ok
  end

  # ---------------------------------------------------------------
  # GET /support_messages (index) — admin only
  # ---------------------------------------------------------------

  test "index redirects unauthenticated visitors to sign in" do
    get support_messages_url
    assert_redirected_to new_user_session_path
  end

  test "index blocks non-admin users" do
    sign_in_as_user
    get support_messages_url
    assert_redirected_to root_path
    assert_equal "You must be an admin", flash[:alert]
  end

  test "admin can list support messages" do
    sign_in_as_admin
    get support_messages_url
    assert_response :ok
    assert_match /Issue with order/, response.body
  end

  # ---------------------------------------------------------------
  # GET /support_messages/:id (show) — admin only
  # ---------------------------------------------------------------

  test "show redirects unauthenticated visitors to sign in" do
    get support_message_url(@message)
    assert_redirected_to new_user_session_path
  end

  test "admin can view a support message" do
    sign_in_as_admin
    get support_message_url(@message)
    assert_response :ok
    assert_match /This is a fairly long message/, response.body
  end

  # ---------------------------------------------------------------
  # PATCH /support_messages/:id (update) — admin only
  # ---------------------------------------------------------------

  test "update redirects unauthenticated visitors to sign in" do
    patch support_message_url(@message), params: { status: "closed" }
    assert_redirected_to new_user_session_path
    assert_equal "open", @message.reload.status
  end

  test "admin can update the status of a support message" do
    sign_in_as_admin
    patch support_message_url(@message), params: { status: "closed" }

    assert_redirected_to support_message_url(@message)
    assert_equal "closed", @message.reload.status
  end

  # ---------------------------------------------------------------
  # DELETE /support_messages/:id (destroy) — admin only
  # ---------------------------------------------------------------

  test "destroy redirects unauthenticated visitors to sign in" do
    assert_no_difference "SupportMessage.count" do
      delete support_message_url(@message)
    end
    assert_redirected_to new_user_session_path
  end

  test "admin can destroy a support message" do
    sign_in_as_admin

    # Known bug (AGENTS.md): `destroy` does not redirect or render a response,
    # so Rails falls back to an implicit empty response. The record IS destroyed.
    assert_difference "SupportMessage.count", -1 do
      delete support_message_url(@message)
    end
  end
end
