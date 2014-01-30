require_relative '../lib/gamesql'

Command.new('testing/schemas/default_game.sql').exec
Command.new('testing/functions/shared.sql').exec