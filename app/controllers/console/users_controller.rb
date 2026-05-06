module Console
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @query = params[:q].to_s.strip
      @users = User.order(created_at: :desc)
      @users = @users.where("email LIKE :query OR display_name LIKE :query OR firebase_uid LIKE :query", query: "%#{@query}%") if @query.present?
      @users = @users.limit(100)
    end

    def show
    end

    def new
      @user = User.new(role: "viewer", status: "active", trust_level: 0)
    end

    def edit
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to console_user_path(@user), notice: "User created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @user.update(user_params)
        redirect_to console_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.update!(status: "archived")
      redirect_to console_users_path, notice: "User archived."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:firebase_uid, :email, :display_name, :role, :status, :trust_level, :notes)
    end
  end
end
