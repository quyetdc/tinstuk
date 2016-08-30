class UsersController < ApplicationController

  #before_action :require_login
  before_action :authenticate_user!
  before_action :set_user, only: [:edit, :profile, :update, :destroy, :get_email, :matches]

  def index
    if params[:id]
      @users = User.gender(current_user).not_me(current_user).where('id < ?', params[:id]).limit(10) - current_user.matches(current_user)
    else
      @users = User.gender(current_user).not_me(current_user).limit(10) - current_user.matches(current_user)
    end

    respond_to do |format|
      format.html
      format.js
    end

  end

  def edit
    authorize! :update, @user
  end

  def update
    if @user.update(users_params)
      respond_to do |format|
        format.html { redirect_to users_path}
      end
    else
      redirect_to edit_user_path(@user)
    end
  end

  def destroy
    
    if @user.destroy
      session[:user_id] = nil
      session[:omniauth] = nil
      redirect_to root_path
    else
      redirect_to edit_user_path(@user)
    end

  end

  def profile
  end

  def matches
    authorize! :read, @user
    @matches = current_user.friendships.where(state: "ACTIVE").map(&:friend) + current_user.inverse_friendships.where(state: "ACTIVE").map(&:user)
  end


  def get_email
    respond_to do |format|
      format.js
    end
  end

  def finish_signup
    # authorize! :update, @user 
    if request.patch? && params[:user] #&& params[:user][:email]
      if @user.update(user_params)
        @user.skip_reconfirmation!
        sign_in(@user, :bypass => true)
        redirect_to @user, notice: 'Your profile was successfully updated.'
      else
        @show_errors = true
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def users_params
    accessible = [ :name, :email, :interest, :bio, :avatar, :location, :date_of_birth ] # extend with your own params
    accessible << [ :password, :password_confirmation ] unless params[:user][:password].blank?
    params.require(:user).permit(accessible)
  end

end