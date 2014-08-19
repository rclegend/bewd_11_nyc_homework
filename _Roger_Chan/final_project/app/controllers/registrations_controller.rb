class RegistrationsController < Devise::RegistrationsController
 
  private
 
  def sign_up_params
    params.require(:user).permit(:home_address, :office_address, :risk_profile, :commute_mode, :email, :password, :password_confirmation)
  end
 
  def account_update_params
    params.require(:user).permit(:home_address, :office_address, :risk_profile, :commute_mode, :email, :password, :password_confirmation, :current_password)
  end
end