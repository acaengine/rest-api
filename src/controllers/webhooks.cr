require "./application"

module Engine::API
  class Webhooks < Application
    base "/api/v1/webhooks/"

    before_action :find_hook

    @trigger : Model::TriggerInstance?

    class WebhookParams < Params
      attribute id : String
      attribute secret : String

      validates :id, presence: true
      validates :secret, presence: true
    end

    def show
      return notify if params["exec"]? == "true"

      render json: @trigger.not_nil!
    end

    # Triggers the webhook
    # 3 types of webhook: (all execute trigger actions, if any)
    #  * Ignore payload
    #  * Perform payload before actions
    #  * Perform payload after actions
    post("/:id/notify", :notify) do
      trig = @trigger.not_nil!
      webhook = (trig.conditions.try &.webhooks.try &.first).not_nil!

      case webhook.type
      when Model::Trigger::Conditions::Webhook::Type::PayloadOnly
        # TODO: Defer to core
        # exec_payload(sys)
        Model::TriggerInstance.increment_trigger_count(trig.id.not_nil!)
        # TODO: Internal to core?
        # trig["#{trig.binding}_count"] += 1
        raise("unimplemented")
      when Model::Trigger::Conditions::Webhook::Type::ExecuteBefore
        # TODO: Defer to core
        # exec_payload(sys)
        # trig.webhook(trig.id)
        raise("unimplemented")
      when Model::Trigger::Conditions::Webhook::Type::ExecuteAfter
        # trig.webhook(trig.id)
        # TODO: Defer to core
        # exec_payload(sys)
        raise("unimplemented")
      when Model::Trigger::Conditions::Webhook::Type::IgnorePayload
        # trig.webhook(trig.id)
        raise("unimplemented")
      end

      head :accepted
    end

    class ExecParams < WebhookParams
      attribute mod : String
      attribute method : String

      # TODO: Generic? Stringly typed? Explicit? Whatever this is?
      attribute args : Array(String | Int64 | Float64) = [] of String | Int64 | Float64

      attribute metadata : String
      attribute index : String

      validates :mod, presence: true
      validates :method, presence: true
    end

    # TODO:
    # def exec_payload(sys)
    #   args = ExecParams.new(params).validate!
    #   mod = sys.get(mod, args[:index] || 1)
    #   mod.method_missing(args[:method], *args[:args])
    # rescue ActionController::ParameterMissing
    #   # payload not included in request
    # end

    def find_hook
      args = WebhookParams.new(params).validate!

      # Find will raise a 404 (not found) if there is an error
      trig = Model::TriggerInstance.find!(args.id)

      has_webhook = (trig.conditions.try &.webhooks.try &.size || 0) > 0

      # Determine the validity of loaded TriggerInstance
      unless trig.enabled &&
             trig.webhook_secret == args.secret &&
             has_webhook
        head :not_found
      end

      @trigger = trig
    end
  end
end