class PlaceSearch < ActiveRecord::Base

  belongs_to :place

  scope :active, where(:active => true)
  default_scope where(:active => true)

  def active?; self.active; end


protected


end