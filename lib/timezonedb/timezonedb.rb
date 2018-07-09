require "rest_client"
require "rb-optionsresolver"

class TimeZoneDB
  def initialize api_key
    @api_key = api_key
    @api_gateway = "http://api.timezonedb.com/v2/"
  end

  def list_time_zone options = Hash.new
    options = validate_list_params options

    execute "list-time-zone", options
  end

  private
  def validate_list_params options
    resolver = OptionsResolver.new

    resolver.set_defaults({
        fields: "all",
        country: "",
        zone: ""
      })
      .set_allowed_values("fields", Proc.new{|fields|
        available_fields = %w(countryCode countryName zoneName gmtOffset timestamp)
        field_arr = fields.split(",").map do |field|
          available_fields.include? field
        end

        fields == "all" || !field_arr.include?(false)
      })
      .set_normalizer("fields", Proc.new{|_, fields| fields.gsub /\s+/, ""})
      .set_allowed_values("country", Proc.new{|country_code| country_code == "" || /^[a-z]{2}$/i.match?(country_code)})

    resolver.resolve options
  end

  def execute url, request_params, method = "get"
    request_params.merge!({
      key: @api_key,
      format: "json"
    })

    begin
      response = RestClient.send method.downcase.to_sym, "#{@api_gateway}#{url}", {params: request_params}

      return JSON.parse response.to_str
    rescue Exception => e
      puts e.message
    end
  end
end
