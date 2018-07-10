Gem::Specification.new do |spec|
  spec.name = "timezonedb-ruby-api"
  spec.version = "0.0.1"
  spec.authors = ["NamNV609"]
  spec.email = ["namnv609@gmail.com"]
  spec.description = "Ruby API client for TimeZoneDB.com"
  spec.summary = "Ruby API client for TimeZoneDB.com"
  spec.license = "MIT"
  spec.homepage = "https://github.com/namnv609/timezonedb-ruby-api"
  spec.files = `git ls-files`.split($/)
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 1.9"

  spec.add_dependency "rest-client", "~> 1.8"
  spec.add_dependency "rb-optionsresolver", "~> 0.0"
end
