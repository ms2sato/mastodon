# frozen_string_literal: true

class SuspendWorker
  include Sidekiq::Worker

  def perform(account_id)
    begin
      account = Account.find(account_id)
      SuspendAccountService.new.call(account)
    rescue
      # nop
    end
  end
end
