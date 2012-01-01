require 'rubygems'
require 'sinatra'

require 'rack/test'
require 'rspec'


set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false


require File.join(File.dirname(__FILE__), '..', 'app')


RSpec.configure do |config|
  config.after(:all) do

  end
end