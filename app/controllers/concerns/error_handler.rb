module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # ハンドルしきれなかったエラーは500エラー扱い
    # 評価は右から左、下から上へなされるのでこの場所で良い。
    # @see http://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html
    rescue_from Exception, with: :render_500

    # @see http://ar156.dip.jp/tiempo/publish/52
    # @see http://morizyun.github.io/blog/custom-error-404-500-page/
    rescue_from ActionController::RoutingError,
                ActionController::UnknownFormat,
                ActiveRecord::RecordNotFound,
                with: :render_404
    rescue_from ActiveRecord::RecordNotUnique, with: :render_409
    rescue_from ActionController::InvalidAuthenticityToken,
                with: :render_422
  end

  def raise_not_found
    raise ActionController::RoutingError, "Routing Error: #{request.original_url}"
  rescue => e
    handle_error(e, 404)
  end

  def render_500(exception = nil)
    handle_error(exception, 500)
  end

  def render_401(exception = nil)
    handle_error(exception, 401)
  end

  def render_403(exception = nil)
    handle_error(exception, 403)
  end

  def render_404(exception = nil)
    handle_error(exception, 404)
  end

  def render_409(exception = nil)
    handle_error(exception, 409)
  end

  def render_422(exception = nil)
    handle_error(exception, 422)
  end

  def process_on_productions(exception, status_code)
    logger.warn("original_fullpath:#{request.original_fullpath}")
    true
  end

  # 基本的にエラーはログを取り#{Rails.root}/public/[status_code].htmlを表示
  def handle_error(exception, status_code)
    process_logging(exception, status_code)
    if behave_productions?
      return unless process_on_productions(exception, status_code)
      return respond_to { |format|
        format.any {
          render_html_for_status_code(status_code)
        }
        format.json {
          render_error_json_from_error exception, status_code
        }
      }
    end

    respond_to { |format|
      format.any {
        raise exception
      }
      format.json {
        render_error_json_from_error exception, status_code
      }
    }
  rescue => ex
    render_html_or_raise_for_status_code(500, ex)
  end

  def render_html_or_raise_for_status_code(status_code, exception)
    raise exception unless behave_productions?
    render_html_for_status_code(status_code)
  end

  def render_html_for_status_code(status_code)
    render file: "#{Rails.root}/public/#{status_code}.html",
           status: status_code, layout: 'application',
           content_type: 'text/html'
  end

  def render_error_json_from_error(error, status_code = :unprocessable_entity)
    render_error_json_with_message(error.message, status_code)
  end

  def render_error_json_from_model(model, status_code = :unprocessable_entity)
    render_error_json_with_message(model.errors.full_messages, status_code)
  end

  def render_error_json_with_message(message, status_code = :unprocessable_entity)
    render json: {status: 'NG', error: message}, status: status_code
  end

  private

  def behave_productions?
    Rails.env.production? || Rails.env.staging?
  end

  def process_logging(exception, status_code)
    return if exception.nil?
    logger.info "Access #{status_code} with exception: #{exception.message}"
    logger.warn(exception.backtrace.join("\n"))
  end
end
