class GamesController < ApplicationController
    def index
        @games = Game.all
        fresh_when(@games.maximum(:updated_at))
    end
end
