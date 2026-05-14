module Bkc
  class AccessLinksController < BaseController
    before_action :require_vault

    def index
      @access_links = @vault.access_links.order(created_at: :desc)
    end

    def new
      @access_link = @vault.access_links.build
    end

    def create
      @access_link = @vault.access_links.build(access_link_params)
      if @access_link.save
        redirect_to bkc_access_links_path, notice: "Access link created"
      else
        render :new
      end
    end

    def show
      @access_link = @vault.access_links.find(params[:id])
    end

    def edit
      @access_link = @vault.access_links.find(params[:id])
    end

    def update
      @access_link = @vault.access_links.find(params[:id])
      if @access_link.update(access_link_params)
        redirect_to bkc_access_links_path, notice: "Access link updated"
      else
        render :edit
      end
    end

    def destroy
      @access_link = @vault.access_links.find(params[:id])
      @access_link.destroy
      redirect_to bkc_access_links_path, notice: "Access link deleted"
    end

    private

    def access_link_params
      params.require(:access_link).permit(:slug, :initial_level, :welcome_message, :expires_at, :max_uses, preset_context: {})
    end

    def require_vault
      @vault = current_vault
      redirect_to bkc_dashboard_path, alert: "No active vault. Please create or select a vault." unless @vault
    end
  end
end
