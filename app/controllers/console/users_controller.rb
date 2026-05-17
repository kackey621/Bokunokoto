module Console
  class UsersController < BaseController
    # MEDIUM-015: emitted to Rails.logger when an admin changes one of
    # these sensitive attributes. AuditLog is vault-scoped (NOT NULL),
    # so platform-scoped events go through the structured logger.
    AUDITED_ATTRIBUTES = %w[role firebase_uid status trust_level].freeze

    before_action :set_user, only: %i[show edit update destroy]

    def index
      @query = params[:q].to_s.strip
      @users = User.order(created_at: :desc)
      if @query.present?
        # MEDIUM-018: escape SQL LIKE metacharacters so a `%` or `_` in
        # the search box does not turn into a wildcard.
        like = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
        @users = @users.where(
          "email LIKE :q OR display_name LIKE :q OR firebase_uid LIKE :q",
          q: like
        )
      end
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
        log_create
        redirect_to console_user_path(@user), notice: "User created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      sensitive_changes = sensitive_changes_for(@user, user_params)

      if @user.update(user_params)
        log_sensitive_changes(sensitive_changes) if sensitive_changes.any?
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

    def sensitive_changes_for(user, attrs)
      AUDITED_ATTRIBUTES.each_with_object({}) do |attr, memo|
        next unless attrs.key?(attr)
        new_value = attrs[attr]
        old_value = user.public_send(attr)
        memo[attr] = [ old_value, new_value ] if new_value.to_s != old_value.to_s
      end
    end

    def log_sensitive_changes(changes)
      actor = current_console_user
      changes.each do |attr, (old_value, new_value)|
        Rails.logger.info(
          "[audit][console_user_update] " \
          "actor_id=#{actor&.id} " \
          "target_user_id=#{@user.id} " \
          "attr=#{attr} " \
          "from=#{old_value.inspect} " \
          "to=#{new_value.inspect}"
        )
      end
    end

    def log_create
      actor = current_console_user
      Rails.logger.info(
        "[audit][console_user_create] " \
        "actor_id=#{actor&.id} " \
        "target_user_id=#{@user.id} " \
        "role=#{@user.role.inspect} " \
        "firebase_uid_present=#{@user.firebase_uid.present?}"
      )
    end
  end
end
