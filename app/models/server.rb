require 'net/http'

class Server  #< ActiveRecord::Base
  # include ActiveModel::Model
  # extend ActiveModel::Callbacks

  def self.broadcast(channel, data)
    puts "#"*100
    puts "BROADCASTING!!! #{channel}"
    puts "#"*100
    message = {:channel => channel, :data => data, :ext => {:auth_token => 'anything'}}
    uri = URI.parse("http://faye-cedar.herokuapp.com/faye")
    Net::HTTP.post_form(uri, :message => message.to_json)
  end
end
