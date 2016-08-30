class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to users_path
  end

  def ensure_signup_complete
    # Ensure we don't go into an infinite loop
    return if action_name == 'finish_signup'

    # Redirect to the 'finish_signup' page if the user
    # email hasn't been verified yet
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end
  
  private

  #def current_user
  #	@current_user ||= User.find(session[:user_id]) if session[:user_id]
  #end

  #def require_login
  #	if session[:user_id] == nil
  #		redirect_to root_path
  #	end
  #end

  #helper_method :require_login
  #helper_method :current_user
  
end


