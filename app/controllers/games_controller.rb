class GamesController < ApplicationController
    def index
        @games = Game.all
        fresh_when(@games)
    end
end
