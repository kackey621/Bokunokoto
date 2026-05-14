module Api
  module V1
    module My
      class ContentsController < BaseController
        include AuditLoggable

        before_action :require_active_vault!

        def index
          contents = current_vault.contents.order(created_at: :desc)
          render json: {
            status: "success",
            contents: contents.map { |c| serialize(c, include_body: false) }
          }
        end

        def create
          content = current_vault.contents.build(content_params)
          if content.save
            log_audit!(action: "create", vault: current_vault, content: content)
            render json: { status: "success", content: serialize(content, include_body: true) }, status: :created
          else
            render json: { status: "error", message: content.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        end

        def update
          content = current_vault.contents.find_by(id: params[:id])
          return render json: { status: "error", message: "not_found" }, status: :not_found unless content

          if content.update(content_params)
            log_audit!(action: "update", vault: current_vault, content: content)
            render json: { status: "success", content: serialize(content, include_body: true) }
          else
            render json: { status: "error", message: content.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        end

        def destroy
          content = current_vault.contents.find_by(id: params[:id])
          return render json: { status: "error", message: "not_found" }, status: :not_found unless content

          log_audit!(action: "delete", vault: current_vault, content: content)
          content.destroy!
          render json: { status: "success" }
        end

        private

        def require_active_vault!
          current_vault!
        end

        def content_params
          params.require(:content).permit(:title, :body, :required_level, :format, :symbol_type, permitted_user_ids: [])
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
      end
    end
  end
end
