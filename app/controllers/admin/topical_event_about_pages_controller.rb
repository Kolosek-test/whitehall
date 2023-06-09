class Admin::TopicalEventAboutPagesController < Admin::BaseController
  before_action :find_topical_event
  before_action :find_page, except: %i[new create]

  helper_method :model_name, :human_friendly_model_name

  layout :get_layout

  def new
    @topical_event_about_page = TopicalEventAboutPage.new
  end

  def create
    @topical_event_about_page = @topical_event.build_topical_event_about_page(about_page_params)
    if @topical_event_about_page.save
      redirect_to admin_topical_event_topical_event_about_pages_path, notice: "About page created"
    else
      render action: "new"
    end
  end

  def update
    if @topical_event_about_page.update(about_page_params)
      redirect_to admin_topical_event_topical_event_about_pages_path, notice: "About page saved"
    else
      render_design_system(:edit, :legacy_edit)
    end
  end

  def show
    @topical_event_about_page = @topical_event.topical_event_about_page
    render_design_system(:show, :legacy_show)
  end

  def model_name
    TopicalEvent.name.underscore
  end

  def human_friendly_model_name
    model_name.humanize
  end

private

  def find_topical_event
    @topical_event = TopicalEvent.friendly.find(params[:topical_event_id])
  end

  def find_page
    @topical_event_about_page = @topical_event.topical_event_about_page
  end

  def about_page_params
    params.require(:topical_event_about_page).permit(:body, :name, :summary, :read_more_link_text)
  end
end

def get_layout
  design_system_actions = []
  design_system_actions += %w[show edit] if preview_design_system?(next_release: false)

  if design_system_actions.include?(action_name)
    "design_system"
  else
    "admin"
  end
end
