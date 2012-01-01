class Audit < ActiveRecord::Base

  STATUSES = {
    :errors     => {:code => 0, :name => 'Error'},
    :successes  => {:code => 1, :name => 'Success'},
    :warnings   => {:code => 2, :name => 'Warning'},
    :notices    => {:code => 3, :name => 'Notice'}
  }


  belongs_to :loggable,   :polymorphic => true

  default_scope :order => 'created_at DESC'
  STATUSES.each{|k,v| scope k, where(:code => v[:code]) }


  def loggable=(r)
    return if r.blank?
    self.loggable_type = r.class.to_s rescue nil unless r.is_a?(Class)
    self.loggable_type ||= r.name rescue nil
    self.loggable_id = r.id rescue nil
  end

  def status=(r); self.status_code = STATUSES[r.to_sym][:code] rescue 0; end
  def status; STATUSES.reject{|k,v| v[:code] != self.status_code}.first[0] rescue :unknown; end


  def self.error(opts)
    begin
      opts = {:script => __FILE__}.merge(opts)
      opts[:status_code] = STATUSES[:errors][:code]
      self.create(opts)
    rescue
      nil
    end
  end
  
  def self.warning(opts)
    begin
      opts = {:script => __FILE__}.merge(opts)
      opts[:status_code] = STATUSES[:warnings][:code]
      self.create(opts)
    rescue
      nil
    end
  end

  def self.success(opts)
    begin
      opts = {:script => __FILE__}.merge(opts)
      opts[:status_code] = STATUSES[:successes][:code]
      self.create(opts)
    rescue
      nil
    end
  end

  def self.notice(opts)
    begin
      opts = {:script => __FILE__}.merge(opts)
      opts[:status_code] = STATUSES[:notices][:code]
      self.create(opts)
    rescue
      nil
    end
  end



protected


end