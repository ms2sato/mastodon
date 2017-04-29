# @see http://easyramble.com/implement-devise-and-ominiauth-on-rails.html
class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    sign_in GithubAuthenticator.new(request.env["omniauth.auth"]).authenticate
    set_flash_message(:notice, :success, kind: 'GitHub') if is_navigational_format?
    redirect_to root_url, event: :authentication
  rescue => e
    set_flash_message :alert, :failure, kind: 'GitHub', reason: e.record.errors.full_messages.join('|')
    p e.message
    p e.record.errors.full_messages
    send_to_rollbar(e)
    redirect_to after_omniauth_failure_path_for(resource_name)
  end
end
