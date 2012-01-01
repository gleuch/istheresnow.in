require "rubygems"

require "bundler"
Bundler.setup

require "sinatra"


configure do
  APP_ENV = Sinatra::Application.environment.to_s
  APP_ROOT = File.expand_path(File.dirname(__FILE__))
  BIN_ROOT = File.expand_path(File.dirname(__FILE__) +"/bin")
  SKIP_AUTHLOGIC = false

  require "./config.rb"
  %w{haml sinatra/respond_to sinatra/content_for sinatra/r18n sinatra/flash}.each{|r| require r}

  # REQUIRE DATABASE MODELS
  Dir.glob("#{APP_ROOT}/models/*.rb").each{|r| require r}

  files = []
  files += Dir.glob("#{APP_ROOT}/lib/*.rb")
  files.each{|r| require r}

  Sinatra::Application.register Sinatra::RespondTo

  FLASH_TYPES = [:alert, :info, :warning, :notice, :success, :error]
  use Rack::Session::Cookie, :key => 'istheresnowin_rack_key', :secret => configatron.cookie_secret, :path => '/', :expire_after => 21600
  set :sessions => true

  # --- I18N -------------------------------
  APP_LOCALES = {
    :en => 'English',
    # :cn => "汉语",
    # :es => 'Espanol'
  }

  Sinatra::Application.register Sinatra::R18n
  set :default_locale, 'en'
  set :translations,   './i18n'

end

before do
  set_current_user_locale
  set_template_defaults
end