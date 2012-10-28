class Weather < ActiveRecord::Base
  
  CACHE_TIMEFRAME = 900 #15.minutes
  
  
  belongs_to :place

  scope :is_snowing, where(:is_snow_event => true)
  scope :is_hurricane, where(:is_hurricane_event => true)
  scope :recent, lambda { where("updated_at >= ?", (Time.now-CACHE_TIMEFRAME)) }
  scope :active, where(:active => true)
  scope :random, :order => "RAND()"
  scope :focus_city, joins(:place).where("places.focus=1")

  default_scope where(:active => true)
  
  
  def recent?; self.updated_at >= (Time.now - CACHE_TIMEFRAME); end
  def name; self.event_name; end
  
  def is_snow?; end

  def snow?; self.is_snow_event; end
  def sleet?; self.is_sleet_event; end
  def rain?; self.is_rain_event; end
  def windy?; self.is_wind_event; end
  def storm?; self.is_storm_event; end
  def sunny?; self.is_sunny_event; end
  def hurricane?; self.is_hurricane_event; end
  def tropical_storm?; self.is_tropical_storm_event; end


protected


end