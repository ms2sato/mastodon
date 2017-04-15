# @see http://easyramble.com/implement-devise-and-ominiauth-on-rails.html
class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    sign_in User.from_omniauth request.env["omniauth.auth"]
    set_flash_message(:notice, :success, kind: "Github") if is_navigational_format?
    redirect_to root_url, event: :authentication
  end
end
