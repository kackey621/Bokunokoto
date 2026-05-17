module Bkc
  class SessionsController < BaseController
    skip_before_action :authenticate_bkc_user!, only: :new
    skip_before_action :ensure_vault_accessible!

    # MEDIUM-024: there is no real BKC login flow yet. This action exists
    # only so the route does not 404 — it explains that the BKC console
    # is reached via Firebase authentication and is not a public
    # credential surface.
    def new
      render :new, layout: "application", status: :ok
    end

    def destroy
      session[:user_id] = nil
      redirect_to root_path, notice: "Signed out from BKC successfully."
    end
  end
end
