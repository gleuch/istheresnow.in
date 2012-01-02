class Weather < ActiveRecord::Base
  
  CACHE_TIMEFRAME = 900 #15.minutes
  
  
  belongs_to :place

  scope :is_snowing, where(:is_snow_event => true)
  scope :recent, lambda { where("recorded_at >= ?", (Time.now-CACHE_TIMEFRAME)) }
  scope :active, where(:active => true)
  scope :random, :order => "RAND()"
  scope :focus_city, joins(:place).where("places.focus=1")

  default_scope where(:active => true)
  
  
  def recent?; self.recored_at >= (Time.now - CACHE_TIMEFRAME); end
  def name; self.event_name; end
  
  def is_snow?; end

  def snow?; ['snow'].include?(self.event_name); end
  def sleet?; ['sleet','ice'].include?(self.event_name); end
  def rain?; ['rain','tstorm','hurricane'].include?(self.event_name); end
  def windy?; ['windy','tornado'].include?(self.event_name); end
  def cloudy?; ['cloudy'].include?(self.event_name); end
  def sunny?; ['sunny'].include?(self.event_name); end


protected


end