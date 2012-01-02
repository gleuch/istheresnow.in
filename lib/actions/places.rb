# Location by params
get %r{/(index)?} do
  pass if params[:q].blank? && params.keys.length < 1
  params[:q] ||= params.keys.shift

  render_place
end

# Location by name
get "/:q" do
  pass if params[:q].blank?

  render_place
end

get "/" do
  @place = Weather.recent.focus_city.is_snowing.random.first.place rescue nil

  respond_to do |format|
    format.html { haml :'places/index' }
  end
end