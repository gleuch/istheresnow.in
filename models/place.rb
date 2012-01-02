class Place < ActiveRecord::Base

  PROXIMITY = 0.01

  has_many :weathers
  has_one :weather, :class_name => 'Weather', :order => 'recorded_at DESC'
  
  has_many :searches, :class_name => 'PlaceSearch'
  has_one :search, :class_name => 'PlaceSearch', :order => 'created_at ASC'


  scope :available, where(:active => true, :available => true)
  scope :active, where(:active => true)
  scope :focus_city, where(:focus => true)
  scope :is_snowing, joins(:weathers).where("weathers.is_snow_event=1")
  scope :near, lambda {|lat,lng|
    select("#{Place::table_name}.*, 3956 * 2 * ASIN(SQRT(POWER(SIN((#{lat} - #{Place::table_name}.geo_latitude)*pi()/180 / 2), 2) +COS(#{lat} * pi()/180) * COS(#{Place::table_name}.geo_latitude * pi()/180) *POWER(SIN((#{lng} - #{Place::table_name}.geo_longitude) * pi()/180 / 2), 2)) ) as distance")
      .order('distance asc').limit(5)
      .where("geo_latitude >= ? AND geo_latitude <= ? AND geo_longitude >= ? AND geo_longitude <= ?", (lat.to_f-PROXIMITY.to_f), (lat.to_f+PROXIMITY.to_f), (lng.to_f-PROXIMITY.to_f), (lng.to_f+PROXIMITY.to_f))
  }

  default_scope where(:active => true, :available => true)


  before_save :cache_nickname


  def name(force=false)
    return self.nickname if !force && !self.nickname.blank?

    # comma separate
    str = []
    str << self.city unless self.city.blank?
    str << self.suburb unless self.suburb.blank?
    str << self.state unless self.state.blank?
    str << self.country_code unless self.country_code.blank?

    # space separate
    str = str.join(', ')
    str << " #{self.postal_code}" unless self.postal_code.blank?

    (str.blank? ? "Unknown Place" : str)
  end

  def active?; self.active; end
  def available?; self.available; end


protected

  def cache_nickname
    self.nickname = name(true)
  end

end