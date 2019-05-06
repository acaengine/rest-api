require "./application"

module Engine::API
  class Zones < Application
    base "/api/v1/zones/"

    # TODO: user access control
    # before_action :check_admin, except: [:index, :show]
    before_action :find_zone, only: [:show, :update, :destroy]
    @zone : Model::Zone?

    def index
      elastic = Model::Zone.elastic
      query = elastic.query(params)
      query.sort = NAME_SORT_ASC

      if params.has_key? "tags"
        tags = params["tags"].gsub(/[^0-9a-z ]/i, "").split(/\s+/).reject(&.empty?).uniq
        return head :bad_request if tags.empty?

        query.must({
          "doc.tags" => tags,
        })
      else
        # TODO: Authorization
        # user = current_user
        # return head :forbidden unless user && (user.support || user.sys_admin)
        query.search_field "doc.name"
      end

      render json: elastic.search(query)
    end

    def show
      if params.has_key? "data"
        key = params["data"]
        settings = @zone.try &.settings || ""
        info_any = JSON.parse(settings)[key]?

        # convert setting string to Array or Hash
        info = info_any.try do |any|
          any.as_h? || any.as_a?
        end

        if info
          render json: info
        else
          head :not_found
        end
      else
        # TODO: Authorization
        # user = current_user
        # head :forbidden unless user && (user.support || user.sys_admin)
        if params.has_key? :complete
          # Include trigger data in response
          render json: serialise_with_fields(@zone, {
            :trigger_data => @zone.try &.trigger_data,
          })
        else
          render json: @zone
        end
      end
    end

    def update
      zone = @zone
      if zone
        zone.assign_attributes(params)
        save_and_respond zone
      end
    end

    def create
      zone = Model::Zone.new(params)
      save_and_respond zone
    end

    def destroy
      @zone.try &.destroy
      head :ok
    end

    private class ZoneParams < Params
      attribute name : String
      attribute description : String
      attribute tags : Array(String)
      attribute triggers : Array(String)
      attribute settings : String
    end

    protected def safe_params
      ZoneParams.new(params).attributes
    end

    protected def find_zone
      # Find will raise a 404 (not found) if there is an error
      @zone = Model::Zone.find!(params["id"]?)
    end
  end
end
