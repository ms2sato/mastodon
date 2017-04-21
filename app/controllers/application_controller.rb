# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ErrorHandler

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  force_ssl if: "Rails.env.production? && ENV['LOCAL_HTTPS'] == 'true'"

  include Localized

  helper_method :current_account
  helper_method :single_user_mode?

  before_action :store_current_location, except: :raise_not_found, unless: :devise_controller?
  before_action :set_user_activity
  before_action :check_suspension, if: :user_signed_in?

  private

  def store_current_location
    store_location_for(:user, request.url)
  end

  def require_admin!
    redirect_to root_path unless current_user&.admin?
  end

  def set_user_activity
    return unless !current_user.nil? && (current_user.current_sign_in_at.nil? || current_user.current_sign_in_at < 24.hours.ago)

    # Mark user as signed-in today
    current_user.update_tracked_fields(request)

    # If the sign in is after a two week break, we need to regenerate their feed
    RegenerationWorker.perform_async(current_user.account_id) if current_user.last_sign_in_at < 14.days.ago
  end

  def check_suspension
    head 403 if current_user.account.suspended?
  end

  protected

  # TODO: check called?
  def gone
    respond_to do |format|
      format.any  { head 410 }
      format.html { render 'errors/410', layout: 'error', status: 410 }
    end
  end

  # --- ErrorHandler ---
  def render_html_for_status_code(status_code)
    return render file: "#{Rails.root}/public/#{status_code}.html",
           status: status_code, layout: 'application',
           content_type: 'text/html' if status_code == 500

    render "errors/#{status_code}", layout: 'error', status: status_code
  end

  def block!
    if self.class.url_without_domain?(request.original_url)
      # 不正アクセスは何も情報を渡さない
      logger.warn('url_without_domain!')
      render nothing: true, status: 404
      return true
    end

    if request.fullpath == '/auth/sign_up'
      render nothing: true, status: 404
      return true
    end

    false
  end

  def process_on_productions(exception, status_code)
    logger.warn("original_fullpath:#{request.original_fullpath}")

    if ENV['ROLLBAR_ACCESS_TOKEN']
      # エラー通知
      logger.warn('send notify_exception')
      Rollbar.error(exception, env: request.env)
    end

    true
  end
  # / --- ErrorHandler ---

  def single_user_mode?
    @single_user_mode ||= Rails.configuration.x.single_user_mode && Account.first
  end

  def current_account
    @current_account ||= current_user.try(:account)
  end

  def cache_collection(raw, klass)
    return raw unless klass.respond_to?(:with_includes)

    raw                    = raw.cache_ids.to_a if raw.is_a?(ActiveRecord::Relation)
    uncached_ids           = []
    cached_keys_with_value = Rails.cache.read_multi(*raw.map(&:cache_key))

    raw.each do |item|
      uncached_ids << item.id unless cached_keys_with_value.key?(item.cache_key)
    end

    klass.reload_stale_associations!(cached_keys_with_value.values) if klass.respond_to?(:reload_stale_associations!)

    unless uncached_ids.empty?
      uncached = klass.where(id: uncached_ids).with_includes.map { |item| [item.id, item] }.to_h

      uncached.values.each do |item|
        Rails.cache.write(item.cache_key, item)
      end
    end

    raw.map { |item| cached_keys_with_value[item.cache_key] || uncached[item.id] }.compact
  end

  private
    def self.match_url_without_domain(str)
      /^https?\:\/\/(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/ =~ str
    end

    def self.url_without_domain?(str)
      self.match_url_without_domain(str) == 0
    end

end
