# Index
get "/manage/log", :auth => :admin do
  @_admin_area = true

  @audits = Audit.all(:limit => 1000)

  respond_to do |format|
    format.html {
      @body_class << 'audits_index'
      haml :'admin/audits/index'
    }
  end
end

# Index
get "/manage/log/status/:status", :auth => :admin do
  @_admin_area = true

  status_code = Audit::STATUSES[ params[:status].to_sym ][:code]# rescue nil unless params[:status].blank?

  @audits = Audit.where(:status_code => status_code).all(:limit => 1000)
  @status = t.audits.status[ params[:status].to_sym ]# rescue 'Unknown'

  respond_to do |format|
    format.html {
      @body_class << 'audits_index'
      haml :'admin/audits/index'
    }
  end
end

# Index
get "/manage/log/:loggable_type", :auth => :admin do
  @_admin_area = true

  @audits = Audit.where(:loggable_type => params[:loggable_type]).all(:limit => 1000)
  @item_type = params[:loggable_type]

  respond_to do |format|
    format.html {
      @body_class << 'audits_index'
      haml :'admin/audits/index'
    }
  end
end

# Index
get "/manage/log/:loggable_type/:loggable_id", :auth => :admin do
  @_admin_area = true

  @audits = Audit.where(:loggable_type => params[:loggable_type], :loggable_id => params[:loggable_id]).all(:limit => 1000)
  @item = @audits.first.loggable rescue nil

  respond_to do |format|
    format.html {
      @body_class << 'audits_index'
      haml :'admin/audits/index'
    }
  end
end