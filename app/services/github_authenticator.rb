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
    user.skip_confirmation! if user.confirmed_at.nil?
    user.save!
    user
  end

  def provider_url
    "https://github.com/#{nickname}"
  end

  def set_properties(user)
    account = user.account

    auth['info']['nickname'] = ENV['GITHUB_TEST_OVERWRITE_NICKNAME'] unless ENV['GITHUB_TEST_OVERWRITE_NICKNAME'].blank?

    # Github nickname has hyphen. change to underscore
    # https://www.npmjs.com/package/github-username-regex#githubusernameregex
    account.username = truncate(
      auth["info"].fetch("nickname"){ auth["uid"] }.downcase.gsub(/\-/, '_'),
      length: 30, omission: ''
    )
    account.display_name = truncate(auth["info"]["name"] || account.username, length: 30, omission: '')
    account.avatar_remote_url = auth["info"]["image"]
    account.note = truncate(auth["info"].fetch('bio') { "" }, length: 160)
  end
end
