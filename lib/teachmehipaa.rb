# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "securerandom"
require "time"
require "uri"

require_relative "teachmehipaa/version"
require_relative "teachmehipaa/core/errors"
require_relative "teachmehipaa/core/json"
require_relative "teachmehipaa/core/transport"
require_relative "teachmehipaa/core/config"
require_relative "teachmehipaa/core/connection"
require_relative "teachmehipaa/core/retries"
require_relative "teachmehipaa/core/token_providers"
require_relative "teachmehipaa/core/model"
require_relative "teachmehipaa/core/union"
require_relative "teachmehipaa/core/pagination"
require_relative "teachmehipaa/core/responses"
require_relative "teachmehipaa/core/multipart"
require_relative "teachmehipaa/core/requestor"
require_relative "teachmehipaa/core/resource"
require_relative "teachmehipaa/core/webhook"
require_relative "teachmehipaa/models"
require_relative "teachmehipaa/resources"
require_relative "teachmehipaa/client"

# The official Ruby library for the TeachMeHIPAA Developer API.
# Start with TeachMeHipaa::Client.
module TeachMeHipaa
end
