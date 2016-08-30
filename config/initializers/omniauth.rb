Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FB_APP_ID'], ENV['FB_APP_SECRET'], { :scope => 'user_location, user_birthday, user_about_me, email'}
end

