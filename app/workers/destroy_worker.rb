# frozen_string_literal: true

class DestroyWorker
  include Sidekiq::Worker

  def perform()
    Account.where(suspended: false).each do |account|
      SuspendWorker.perform_async(account.id)
    end
  end
end
