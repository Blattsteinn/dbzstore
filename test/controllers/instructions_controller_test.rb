require "test_helper"

class InstructionsControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------
  # GET /instructions (instructions)
  # ---------------------------------------------------------------

  test "instructions page is publicly accessible" do
    get instructions_url
    assert_response :ok
  end

  test "instructions page renders the delivery instructions and contact details" do
    get instructions_url

    assert_response :ok
    assert_match /Account delivery instructions/, response.body
    assert_match /@dokkanarnis/, response.body
    assert_match /dokkanriftmanagement@tuta\.com/, response.body
  end
end
