# frozen_string_literal: true

class Settings::FollowerDomainsController < ApplicationController
  layout 'admin'

  before_action :authenticate_user!

  def show
    @account = current_account
    @domains = current_account.followers.reorder(nil).group('accounts.domain').select('accounts.domain, count(accounts.id) as accounts_from_domain').page(params[:page]).per(10)
  end

  def update
    domains = bulk_params[:select] || []

    domains.each do |domain|
      SoftBlockDomainFollowersWorker.perform_async(current_account.id, domain)
    end

    redirect_to settings_follower_domains_path, notice: I18n.t('followers.success', count: domains.size)
  end

  private

  def bulk_params
    params.permit(select: [])
  end
end
