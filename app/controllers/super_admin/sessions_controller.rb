module SuperAdmin
  class SessionsController < BaseController
    skip_before_action :authenticate_super_admin!, only: [:new, :create]
    layout "super_admin_login"

    def new
      # Form logic is handled in the view
    end

    def create
      manager = Manager.find_by(email: params[:email].downcase.strip)
      
      if manager&.authenticate(params[:password])
        session[:manager_id] = manager.id
        redirect_to super_admin_root_path, notice: "Signed in successfully."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session[:manager_id] = nil
      redirect_to new_super_admin_session_path, notice: "Signed out successfully."
    end
  end
end
