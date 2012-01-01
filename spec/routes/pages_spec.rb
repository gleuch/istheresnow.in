require File.dirname(File.dirname(__FILE__)) + '/spec_helper'

describe 'IsThereSnowInApp (/)' do
  include Rack::Test::Methods

  def app; Sinatra::Application; end
  
  

end