module ApplicationHelper
  def joinable game
    puts "game joinable! #{game.to_json}"
    game.p2 == nil
  end
end
