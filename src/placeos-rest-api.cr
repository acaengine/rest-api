require "action-controller/logger"
require "log_helper"
require "secrets-env"

require "./constants"
require "./placeos-rest-api/controllers/application"
require "./placeos-rest-api/controllers/*"

module PlaceOS::Api
  Log = ::Log.for(self)

  class_getter? production : Bool = PROD
end
