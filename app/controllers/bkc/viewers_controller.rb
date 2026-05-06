module Bkc
  class ViewersController < BaseController
    def index
      @permissions = current_vault.permissions.includes(:user)
    end

    def show
      @permission = current_vault.permissions.find(params[:id])
      @user = @permission.user
    end

    def update
      @permission = current_vault.permissions.find(params[:id])
      
      if @permission.update(permission_params)
        redirect_to bkc_viewer_path(@permission), notice: "Trust level updated for #{@permission.user.display_name}."
      else
        render :show, alert: "Error updating trust level."
      end
    end

    private

    def permission_params
      params.require(:permission).permit(:granted_level, :status, :owner_notes)
    end
  end
end
