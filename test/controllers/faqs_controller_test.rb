require "test_helper"

class FaqsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @faq = Faq.create!(question: "How fast is delivery?", answer: "Usually within 24 hours.")
  end

  def sign_in_as_admin
    sign_in User.create!(email: "admin@example.com", password: "password123", admin: true)
  end

  def sign_in_as_user
    sign_in User.create!(email: "user@example.com", password: "password123")
  end

  # ---------------------------------------------------------------
  # GET /faqs (index) — public
  # ---------------------------------------------------------------

  test "index is publicly accessible and lists faqs" do
    get faqs_url

    assert_response :ok
    assert_select "details.faq-item", 1
    assert_match /How fast is delivery\?/, response.body
  end

  test "index renders an empty state when there are no faqs" do
    Faq.delete_all

    get faqs_url

    assert_response :ok
    assert_select "p.faq-empty"
  end

  # ---------------------------------------------------------------
  # GET /faqs/new (new)
  # ---------------------------------------------------------------

  test "new redirects unauthenticated visitors to sign in" do
    get new_faq_url
    assert_redirected_to new_user_session_path
  end

  test "new blocks non-admin users" do
    sign_in_as_user
    get new_faq_url
    assert_redirected_to root_path
    assert_equal "You must be an admin", flash[:alert]
  end

  test "admin can access the new faq form" do
    sign_in_as_admin
    get new_faq_url
    assert_response :ok
  end

  # ---------------------------------------------------------------
  # POST /faqs (create)
  # ---------------------------------------------------------------

  test "create redirects unauthenticated visitors to sign in" do
    assert_no_difference "Faq.count" do
      post faqs_url, params: { faq: { question: "New question?", answer: "New answer." } }
    end
    assert_redirected_to new_user_session_path
  end

  test "admin can create a faq and redirects to the dashboard" do
    sign_in_as_admin

    assert_difference "Faq.count", 1 do
      post faqs_url, params: { faq: { question: "New question?", answer: "New answer." } }
    end

    assert_equal "New question?", Faq.last.question
    assert_redirected_to dashboard_faqs_url
  end

  test "create with invalid params re-renders the new form" do
    sign_in_as_admin

    assert_no_difference "Faq.count" do
      post faqs_url, params: { faq: { question: "", answer: "" } }
    end

    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------
  # GET /faqs/:id/edit (edit)
  # ---------------------------------------------------------------

  test "edit redirects unauthenticated visitors to sign in" do
    get edit_faq_url(@faq)
    assert_redirected_to new_user_session_path
  end

  test "admin can access the edit form" do
    sign_in_as_admin
    get edit_faq_url(@faq)
    assert_response :ok
  end

  # ---------------------------------------------------------------
  # PATCH /faqs/:id (update)
  # ---------------------------------------------------------------

  test "update redirects unauthenticated visitors to sign in" do
    patch faq_url(@faq), params: { faq: { question: "Changed?" } }
    assert_redirected_to new_user_session_path
    assert_equal "How fast is delivery?", @faq.reload.question
  end

  test "admin can update a faq" do
    sign_in_as_admin
    patch faq_url(@faq), params: { faq: { question: "Changed?", answer: "Changed answer." } }

    assert_redirected_to dashboard_faqs_url
    assert_equal "Changed?", @faq.reload.question
    assert_equal "Changed answer.", @faq.reload.answer
  end

  # ---------------------------------------------------------------
  # DELETE /faqs/:id (destroy)
  # ---------------------------------------------------------------

  test "destroy redirects unauthenticated visitors to sign in" do
    assert_no_difference "Faq.count" do
      delete faq_url(@faq)
    end
    assert_redirected_to new_user_session_path
  end

  test "admin can destroy a faq" do
    sign_in_as_admin

    assert_difference "Faq.count", -1 do
      delete faq_url(@faq)
    end

    assert_redirected_to dashboard_faqs_url
  end
end
