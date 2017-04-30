# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('SMTP_FROM_ADDRESS') { 'notifications@localhost' }
  layout 'mailer'
  helper :instance

  def mail(headers = {}, &block)
    return puts "email not found: #{headers}" if headers[:to].end_with?('@github')
    super(headers) { |format| block.call(format) if block.present? }
  end
end
