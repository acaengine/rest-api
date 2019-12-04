require "./application"

module ACAEngine::Api
  class Settings < Application
    base "/api/engine/v2/settings/"

    before_action :check_admin, except: [:index, :show]
    before_action :check_support, only: [:index, :show]

    before_action :find_settings, only: [:show, :update, :destroy]

    @settings : Model::Settings?
    getter :settings

    def index
      if params.has_key? "parent_id"
        parents = params["parent_id"].split(',')

        # Directly search for model's settings
        parent_settings = Model::Settings.for_parent(parents)
        # Decrypt for the user
        parent_settings.each &.decrypt_for!(current_user)

        render json: parent_settings
      else
        elastic = Model::Settings.elastic
        query = elastic.query(params)

        render json: elastic.search(query)
      end
    end

    def show
      render json: current_settings.decrypt_for!(current_user)
    end

    def update
      current_settings.assign_attributes_from_json(request.body.as(IO))
      save_and_respond current_settings
    end

    def create
      save_and_respond Model::Settings.from_json(request.body.as(IO))
    end

    def destroy
      current_settings.destroy
      head :ok
    end

    # Helpers
    ###########################################################################

    def current_settings : Model::Settings
      return @settings.as(Model::Settings) if @settings
      find_settings
    end

    def find_settings
      # Find will raise a 404 (not found) if there is an error
      @settings = Model::Settings.find!(params["id"]?)
    end
  end
end
