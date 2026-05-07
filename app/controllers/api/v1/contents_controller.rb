module Api
  module V1
    class ContentsController < BaseController
      after_action :log_view_activity, only: [ :show ]

      def index
        vault = Vault.find_by(id: params[:vault_id])
        return render_not_found unless vault && readable_vault?(vault)

        contents = Content.accessible_for(current_user, vault, platform: current_platform)
        render json: { status: "success", contents: contents.map { |c| serialize(c) } }
      end

      def show
        @content = Content.find_by(id: params[:id])
        return render_not_found unless @content

        accessible = Content.accessible_for(current_user, @content.vault, platform: current_platform)
        return render_not_found unless accessible.exists?(id: @content.id)

        render json: { status: "success", content: serialize(@content, include_body: true) }
      end

      private

      def readable_vault?(vault)
        return true if current_user.vault == vault

        current_user.permissions.exists?(vault: vault, status: "active")
      end

      def serialize(content, include_body: false)
        data = {
          id: content.id,
          vault_id: content.vault_id,
          title: content.title,
          required_level: content.required_level,
          format: content.format,
          symbol_type: content.symbol_type,
          updated_at: content.updated_at
        }
        data[:body] = content.body if include_body
        data
      end

      def log_view_activity
        return unless @content && current_user
        AuditLog.create!(
          user: current_user,
          content: @content,
          action: "view",
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          occurred_at: Time.current
        )
      end

      def render_not_found
        render json: { status: "error", message: "not_found" }, status: :not_found
      end

      def current_platform
        request.headers["X-BK-Platform"]
      end
    end
  end
end
