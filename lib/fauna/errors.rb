module Fauna
  ##
  # Error returned by the FaunaDB server.
  # For documentation of error types, see the `docs <https://faunadb.com/documentation#errors>`__.
  class FaunaError < RuntimeError
    ##
    # Either an error or a list of errors representing the fault encountered.
    # Can also be a simple message.
    attr_reader :errors

    # RequestResult for the request that caused this error.
    attr_reader :request_result

    def self.raise_for_status_code(request_result)
      case request_result.status_code
      when 200..299

      when 400
        fail BadRequest.new(request_result)
      when 401
        fail Unauthorized.new(request_result)
      when 403
        fail PermissionDenied.new(request_result)
      when 404
        fail NotFound.new(request_result)
      when 405
        fail MethodNotAllowed.new(request_result)
      when 500
        fail InternalError.new(request_result)
      when 503
        fail UnavailableError.new(request_result)
      else
        fail FaunaError.new(request_result)
      end
    end

    ##
    # Creates a new \Fauna error
    #
    # +errors+:: Takes one of three forms:
    #            :: A hash with a list of errors under +errors+.
    #            :: A hash with a simple error.
    #            :: A simple string as the message.
    def initialize(request_result)
      @request_result = request_result
      @errors = request_result.response_content[:errors].map(&ErrorData.method(:from_hash))
      super(@errors ? @errors[0].description : '(empty `errors`)')
    end
  end

  # An exception thrown if FaunaDB cannot evaluate a query.
  class BadRequest < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 401.
  class Unauthorized < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 403.
  class PermissionDenied < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 404 for non-query endpoints.
  class NotFound < FaunaError; end

  # An exception thrown if FaunaDB responds with an HTTP 405.
  class MethodNotAllowed < FaunaError; end

  ##
  # An exception thrown if FaunaDB responds with an HTTP 500. Such errors represent an internal
  # failure within the database.
  class InternalError < FaunaError; end

  ##
  # An exception thrown if FaunaDB responds with an HTTP 503.
  class UnavailableError < FaunaError; end

  # :section: ErrorData

  # Data for one error returned by the server.
  class ErrorData
    def self.from_hash(hash)
      code = hash[:code]
      description = hash[:description]
      position = ErrorHelpers.map_position hash[:position]
      if code == 'validation failed'
        failures = hash[:failures].map(&Failure.method(:from_hash))
        ValidationFailed.new description, position, failures
      else
        ErrorData.new code, description, position
      end
    end

    ##
    # Error code.
    #
    # Reference: {FaunaDB Error codes}[https://faunadb.com/documentation#errors]
    attr_reader :code
    # Error description.
    attr_reader :description
    # Position of the error in a query. May be nil.
    attr_reader :position

    def initialize(code, description, position)
      @code = code
      @description = description
      @position = position
    end

    def inspect
      "ErrorData(#{code.inspect}, #{description.inspect}, #{position.inspect})"
    end
  end

  # An ErrorData that also stores Failure information.
  class ValidationFailed < ErrorData
    # Lit of +Failure+ objects returned by the server.
    attr_reader :failures

    def initialize(description, position, failures)
      super('validation failed', description, position)
      @failures = failures
    end

    def inspect
      "ValidationFailed(#{description.inspect}, #{position.inspect}, #{failures.inspect})"
    end
  end

  ##
  # Part of a +ValidationFailed+.
  # See the "Invalid Data" section of the {docs}[https://faunadb.com/documentation#errors].
  class Failure
    def self.from_hash(hash)
      Failure.new hash[:code], hash[:description], ErrorHelpers.map_position(hash[:field])
    end

    # Failure code.
    attr_reader :code
    # Failure description.
    attr_reader :description
    # Field of the failure in the instance.
    attr_reader :field

    def initialize(code, description, field)
      @code = code
      @description = description
      @field = field
    end

    def inspect
      "Failure(#{code.inspect}, #{description.inspect}, #{field.inspect})"
    end
  end

  module ErrorHelpers #:nodoc:
    def self.map_position(position)
      if position.nil?
        nil
      else
        position.map do |part|
          if part.is_a? String
            part.to_sym
          else
            part
          end
        end
      end
    end
  end
end
