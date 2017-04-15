# frozen_string_literal: true

class User < ApplicationRecord
  include Settings::Extend

  devise :trackable, :validatable, :omniauthable,
         :two_factor_authenticatable, otp_secret_encryption_key: ENV['OTP_SECRET'],
         omniauth_providers: [:github]

  belongs_to :account, inverse_of: :user
  accepts_nested_attributes_for :account

  validates :account, presence: true
  validates :locale, inclusion: I18n.available_locales.map(&:to_s), unless: 'locale.nil?'
  validates :email, email: true

  scope :prolific,  -> { joins('inner join statuses on statuses.account_id = users.account_id').select('users.*, count(statuses.id) as statuses_count').group('users.id').order('statuses_count desc') }
  scope :recent,    -> { order('id desc') }
  scope :admins,    -> { where(admin: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def setting_default_privacy
    settings.default_privacy || (account.locked? ? 'private' : 'public')
  end

  def setting_boost_modal
    settings.boost_modal
  end


  def self.from_omniauth(auth)
    user = User.joins(:account).find_by(accounts: {provider: auth["provider"], uid: auth["uid"]})
    unless user
      user = self.new
      user.email =  auth["info"]["email"]
      user.build_account(
        uid:auth["uid"],
        provider: auth["provider"]
      )
      user.password = Devise.friendly_token[0, 20]
    end

    set_properties(user, auth)
    user.save!
    user
  end

  def provider_url
    "https://github.com/#{nickname}"
  end

  def self.set_properties(user, auth)
    account = user.account

    account.token = auth["credentials"]["token"]
    account.username = auth["info"]["nickname"]
    account.display_name = auth["info"]["name"] || auth["info"]["nickname"]
    account.avatar_remote_url = auth["info"]["image"]
    account.note = auth["info"].fetch('bio') { "" }
  end
end
