module Bkc
  class ContentsController < BaseController
    before_action :set_content, only: %i[edit update destroy]

    def index
      @contents = current_vault.contents.order(created_at: :desc)
    end

    def new
      @content = current_vault.contents.build(required_level: 0, format: "markdown")
    end

    def create
      @content = current_vault.contents.build(content_params)
      if @content.save
        redirect_to bkc_contents_path, notice: "Content created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @content.update(content_params)
        redirect_to bkc_contents_path, notice: "Content updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @content.destroy!
      redirect_to bkc_contents_path, notice: "Content deleted."
    end

    private

    def set_content
      @content = current_vault.contents.find(params[:id])
    end

    def content_params
      params.require(:content).permit(:title, :body, :required_level, :format, :symbol_type)
    end
  end
end
