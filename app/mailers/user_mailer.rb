# frozen_string_literal: true

class UserMailer < Devise::Mailer
  default from: ENV.fetch('SMTP_FROM_ADDRESS') { 'notifications@localhost' }
  layout 'mailer'

  helper :instance

  def mail(headers = {}, &block)
    return puts "email not found: #{headers}" if headers[:to].end_with?('@github')
    super
  end

  def confirmation_instructions(user, token, _opts = {})
    @resource = user
    @token    = token
    @instance = Rails.configuration.x.local_domain

    I18n.with_locale(@resource.locale || I18n.default_locale) do
      mail to: @resource.unconfirmed_email.blank? ? @resource.email : @resource.unconfirmed_email, subject: I18n.t('devise.mailer.confirmation_instructions.subject', instance: @instance)
    end
  end

  def reset_password_instructions(user, token, _opts = {})
    @resource = user
    @token    = token

    I18n.with_locale(@resource.locale || I18n.default_locale) do
      mail to: @resource.email, subject: I18n.t('devise.mailer.reset_password_instructions.subject')
    end
  end

  def password_change(user, _opts = {})
    @resource = user

    I18n.with_locale(@resource.locale || I18n.default_locale) do
      mail to: @resource.email, subject: I18n.t('devise.mailer.password_change.subject')
    end
  end

  def last_mail(user)
    @user = user
    mail to: user.email, subject: "[重要なお知らせ]mstdn.techdrive.topは近日中に停止します"
  end
end
