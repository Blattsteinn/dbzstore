require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dokkan  = Game.create!(name: "dokkan",  official_name: "DBZ Dokkan Battle")
    @legends = Game.create!(name: "legends", official_name: "DRAGON BALL LEGENDS")
  end

  # ---------------------------------------------------------------
  # GET /games (index)
  # ---------------------------------------------------------------

  test "index is publicly accessible and lists games" do
    get games_url

    assert_response :ok
    assert_select ".game-card", 2
    assert_match /DBZ Dokkan Battle/, response.body
    assert_match /DRAGON BALL LEGENDS/, response.body
  end

  test "index links each game to its products page" do
    get games_url

    assert_response :ok
    assert_select "a.game-card[href=?]", game_products_path("dokkan")
    assert_select "a.game-card[href=?]", game_products_path("legends")
  end

  test "index renders an empty state when there are no games" do
    Game.delete_all

    get games_url

    assert_response :ok
    assert_select ".empty-state"
  end
end
