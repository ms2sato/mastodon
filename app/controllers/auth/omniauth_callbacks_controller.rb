# @see http://easyramble.com/implement-devise-and-ominiauth-on-rails.html
class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    sign_in GithubAuthenticator.new(request.env["omniauth.auth"]).authenticate
    set_flash_message(:notice, :success, kind: "Github") if is_navigational_format?
    redirect_to root_url, event: :authentication
  rescue => e
    p e.record.errors
    Rails.logger.warn e.record.errors
    raise e
  end

  def after_omniauth_failure_path_for(_)
    about_path
  end
end
