require "test_helper"

class DiscountsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @discount = Discount.create!(code: "WELCOME10", amount: 10, remaining: 10)
  end

  def sign_in_as_admin
    sign_in User.create!(email: "admin@example.com", password: "password123", admin: true)
  end

  def sign_in_as_user
    sign_in User.create!(email: "user@example.com", password: "password123")
  end

  # ---------------------------------------------------------------
  # GET /discounts (index)
  # ---------------------------------------------------------------

  test "index redirects unauthenticated visitors to sign in" do
    get discounts_url
    assert_redirected_to new_user_session_path
  end

  test "index blocks non-admin users" do
    sign_in_as_user
    get discounts_url
    assert_redirected_to root_path
    assert_equal "You must be an admin", flash[:alert]
  end

  test "admin can list discounts" do
    sign_in_as_admin
    get discounts_url
    assert_response :success
    assert_select "body", /WELCOME10/
  end

  # ---------------------------------------------------------------
  # GET /discounts/:id (show)
  # ---------------------------------------------------------------

  test "show redirects unauthenticated visitors to sign in" do
    get discount_url(@discount)
    assert_redirected_to new_user_session_path
  end

  test "admin can view a discount" do
    sign_in_as_admin
    get discount_url(@discount)
    assert_response :success
    assert_select "body", /WELCOME10/
  end

  # ---------------------------------------------------------------
  # GET /discounts/new (new)
  # ---------------------------------------------------------------

  test "new redirects unauthenticated visitors to sign in" do
    get new_discount_url
    assert_redirected_to new_user_session_path
  end

  test "admin can access the new discount form" do
    sign_in_as_admin
    get new_discount_url
    assert_response :success
  end

  # ---------------------------------------------------------------
  # POST /discounts (create)
  # ---------------------------------------------------------------

  test "create redirects unauthenticated visitors to sign in" do
    assert_no_difference "Discount.count" do
      post discounts_url, params: { discount: { code: "SUMMER", amount: 20 } }
    end
    assert_redirected_to new_user_session_path
  end

  test "admin creates a discount and defaults remaining to amount" do
    sign_in_as_admin

    assert_difference "Discount.count", 1 do
      post discounts_url, params: { discount: { code: "SUMMER", amount: 20 } }
    end

    discount = Discount.last
    assert_equal "SUMMER", discount.code
    assert_equal 20, discount.amount
    assert_equal 20, discount.remaining
    assert_redirected_to discounts_path
  end

  test "create with invalid params re-renders the new form" do
    sign_in_as_admin

    assert_no_difference "Discount.count" do
      post discounts_url, params: { discount: { code: "", amount: -5 } }
    end

    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------
  # GET /discounts/:id/edit (edit)
  # ---------------------------------------------------------------

  test "edit redirects unauthenticated visitors to sign in" do
    get edit_discount_url(@discount)
    assert_redirected_to new_user_session_path
  end

  test "admin can access the edit form" do
    sign_in_as_admin
    get edit_discount_url(@discount)
    assert_response :success
  end

  # ---------------------------------------------------------------
  # PATCH /discounts/:id (update)
  # ---------------------------------------------------------------

  test "update redirects unauthenticated visitors to sign in" do
    patch discount_url(@discount), params: { discount: { code: "NEWCODE" } }
    assert_redirected_to new_user_session_path
    assert_equal "WELCOME10", @discount.reload.code
  end

  test "admin can update a discount" do
    sign_in_as_admin
    patch discount_url(@discount), params: { discount: { code: "NEWCODE", amount: 25, remaining: 5 } }

    assert_redirected_to discounts_path
    assert_equal "NEWCODE", @discount.reload.code
    assert_equal 25, @discount.amount
    assert_equal 5, @discount.remaining
  end

  test "update with invalid params re-renders the edit form" do
    sign_in_as_admin
    patch discount_url(@discount), params: { discount: { code: "", amount: -1 } }

    assert_response :unprocessable_entity
    assert_equal "WELCOME10", @discount.reload.code
  end

  # ---------------------------------------------------------------
  # DELETE /discounts/:id (destroy)
  # ---------------------------------------------------------------

  test "destroy redirects unauthenticated visitors to sign in" do
    assert_no_difference "Discount.count" do
      delete discount_url(@discount)
    end
    assert_redirected_to new_user_session_path
  end

  test "admin can destroy a discount" do
    sign_in_as_admin

    assert_difference "Discount.count", -1 do
      delete discount_url(@discount)
    end

    assert_redirected_to discounts_path
  end
end
