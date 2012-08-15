module IPWhitelistedController
  include ActiveSupport::Concern

  def self.included(base)
    return unless ConfigHelper.get(:ip_whitelist)

    base.before_filter :restrict_ip_address
    base.before_filter :authenticate_user!
  end

  private

  def restrict_ip_address
    head 403 unless ConfigHelper.get(:ip_whitelist).include?(request.env['REMOTE_ADDR'])
  end

end
