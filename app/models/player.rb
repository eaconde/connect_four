class Player < ActiveRecord::Base
  has_many :games
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def self.get_or_create_fake
    self.find_or_create_by(name: "Player 2") #do |user|
    #   user.session_id = "second_player_application_generated"
    # end
  end

  def to_s
    self.name
  end
end
