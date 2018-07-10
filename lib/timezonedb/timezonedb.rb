require "rest_client"
require "rb-optionsresolver"
require "date"

class TimeZoneDB
  ISO_3166_CODE_REGEXP = /^[a-z]{2}$/i

  def initialize api_key
    @api_key = api_key
    @api_gateway = "http://api.timezonedb.com/v2/"
  end

  def list_time_zone options = Hash.new
    options = validate_list_params options

    execute "list-time-zone", options
  end

  def get_time_zone options = Hash.new
    options = validate_get_time_zone_params options

    execute "get-time-zone", options
  end

  def convert_time_zone options = Hash.new
    options = validate_convert_time_zone_params options

    execute "convert-time-zone", options
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
      .set_allowed_values("country", Proc.new{|country_code| country_code == "" || ISO_3166_CODE_REGEXP.match?(country_code)})

    resolver.resolve options
  end

  def validate_get_time_zone_params options
    resolver = OptionsResolver.new

    resolver.set_defaults({
      fields: "all", zone: "", lat: "", lng: "", country: "", city: ""
    })
    .set_defined(%w(region page time))
    .set_required("by")
    .set_allowed_values("fields", Proc.new{|fields|
      available_fields = %w(countryCode countryName regionName cityName zoneName
        abbreviation gmtOffset dst dstStart dstEnd nextAbbreviation timestamp formatted)
      field_arr = fields.split(",").map do |field|
        available_fields.include? field
      end

      fields == "all" || !field_arr.include?(false)
    })
    .set_allowed_values("by", %w(zone position city ip))
    .set_allowed_values("region", lambda{|region_code| region_code == "" || ISO_3166_CODE_REGEXP.match?(region_code)})
    .set_normalizer("zone", lambda{|options, zone| set_required_if options, zone, "zone", "zone"})
    .set_normalizer("lat", lambda{|options, lat| set_required_if options, lat, "lat", "position"})
    .set_normalizer("lng", lambda{|options, lng| set_required_if options, lng, "lng", "position"})
    .set_normalizer("country", lambda{|options, country| set_required_if options, country, "country", "city"})
    .set_normalizer("city", lambda{|options, city| set_required_if options, city, "city", "city"})

    get_time_zone_params = resolver.resolve options

    options.reject{|elm| elm.to_s == "" || elm.is_a?(FalseClass)}
  end

  def validate_convert_time_zone_params options
    resolver = OptionsResolver.new

    resolver.set_defaults({fields: "all"})
      .set_defined("time")
      .set_required(%w(from to))
      .set_allowed_values("fields", Proc.new{|fields|
        available_fields = %w(fromZoneName fromAbbreviation fromTimestamp toZoneName
          toAbbreviation toTimestamp offset)
        field_arr = fields.split(",").map do |field|
          available_fields.include? field
        end

        fields == "all" || !field_arr.include?(false)
      })
      .set_normalizer("time", Proc.new{|options, time|
        raise InvalidParameter, "Time is invalid datetime format" unless [DateTime, Integer, Time, String].include?(time.class)

        time = DateTime.parse time if time.is_a?(String)
        time = time.to_time.to_i if [DateTime, Time].include?(time.class)

        time
      })

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

  def set_required_if options, field_val, current_field, other_field
    lookup_by = options["by"]

    if lookup_by == other_field && field_val.empty?
      raise InvalidOptions, "\"#{current_field}\" must be set when use lookup by \"#{other_field}\""
    end

    field_val
  end
end
