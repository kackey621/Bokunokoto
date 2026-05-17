# Be sure to restart your server when you modify this file.
#
# Defines an application-wide Content Security Policy.
# Shipped in *report-only* mode for the first release after the
# 2026-05-17 audit — inline <script> blocks in
# app/views/bkc/analytics/show.html.erb and
# app/views/bkc/forensics/index.html.erb still need to be lifted into
# nonce-tagged helpers before this can be flipped to enforcing.
#
# See HIGH-005 / LOW-026 in security-audit-report-2026-05-17.md.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, "https://cdn.jsdelivr.net"
    policy.style_src   :self, :https, "https://cdn.jsdelivr.net"
    policy.connect_src :self, :https
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  config.content_security_policy_report_only = true
end
