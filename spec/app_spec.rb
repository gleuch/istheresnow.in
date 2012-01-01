require File.dirname(__FILE__) + '/spec_helper'

describe 'IsThereSnowInApp' do
  include Rack::Test::Methods

  def app; Sinatra::Application; end

  # ['/', '/test/test', '/test2', '/omg', '?content=1&upload_token=1'].each do |file|
  #   context "GET #{file}" do
  #     it "should fail" do
  #       get file
  #       last_response.status.should be(404)
  #     end
  #   end
  # 
  #   context "POST #{file}" do
  #     it "should fail" do
  #       post file
  #       last_response.status.should be(404)
  #     end
  #   end
  # end
  # 
  # # Ensure these are 404'd as GET
  # ['/test', '/status', '/verify', '/initalize'].each do |file|
  #   context "GET #{file}" do
  #     it "should fail" do
  #       get file
  #       last_response.status.should be(404)
  #     end
  #   end
  # end

end