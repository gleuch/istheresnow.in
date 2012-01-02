set(:auth) do |*roles|   # <- notice the splat here
  condition do
    unless roles.any? {|role| send("is_#{role}?") }
      redirect "/login", 303 
    end
  end
end

set(:check) do |*checks|
  condition do
    unless checks.any? {|check| send("is_#{check}") }
      raise ActiveRecord::RecordNotFound
    end
  end
end


%w(audits places pages).each{|r| require "#{APP_ROOT}/lib/actions/#{r}"}