class GithubAuthenticator < BaseService
  attr_accessor :auth

  def initialize(auth)
    @auth = auth
  end

  def authenticate
    user = User.joins(:account).find_by(accounts: {provider: auth["provider"], uid: auth["uid"]})
    unless user
      user = User.new
      user.email =  auth["info"]["email"] || "#{auth["uid"]}@#{auth["provider"]}"
      user.build_account(
        uid: auth["uid"],
        provider: auth["provider"]
      )
      user.password = Devise.friendly_token[0, 20]
      set_properties user
    end

    user.account.token = auth["credentials"]["token"]
    user.skip_confirmation!
    user.save!
    user
  end

  def provider_url
    "https://github.com/#{nickname}"
  end

  def set_properties(user)
    account = user.account

    account.username = auth["info"]["nickname"] || auth["uid"]
    account.display_name = auth["info"]["name"] || account.username
    account.avatar_remote_url = auth["info"]["image"]
    account.note = auth["info"].fetch('bio') { "" }
  end
end
