require 'tzinfo'
require 'active_support'
require 'active_support/deprecation'
require 'active_support/core_ext'
require 'active_support/concern'
require 'singleton'

require 'active_model'

require 'active_data/version'
require 'active_data/errors'
require 'active_data/extensions'
require 'active_data/config'
require 'active_data/railtie' if defined? Rails
require 'active_data/model'
require 'active_data/persistence_adapters'

module ActiveData
  BOOLEAN_MAPPING = {
    1 => true,
    0 => false,
    '1' => true,
    '0' => false,
    't' => true,
    'f' => false,
    'T' => true,
    'F' => false,
    true => true,
    false => false,
    'true' => true,
    'false' => false,
    'TRUE' => true,
    'FALSE' => false,
    'y' => true,
    'n' => false,
    'yes' => true,
    'no' => false
  }.freeze

  def self.config
    ActiveData::Config.instance
  end

  singleton_class.delegate(*ActiveData::Config.delegated, to: :config)

  typecaster('Object') { |value, attribute| value if value.class < attribute.type }
  typecaster('String') { |value, _| value.to_s }
  typecaster('Array') do |value|
    case value
    when ::Array then
      value
    when ::String then
      value.split(',').map(&:strip)
    end
  end
  typecaster('Hash') do |value|
    case value
    when ::Hash then
      value
    end
  end
  typecaster('Date') do |value|
    begin
      value.to_date
    rescue ArgumentError, NoMethodError
      nil
    end
  end
  typecaster('DateTime') do |value|
    begin
      value.to_datetime
    rescue ArgumentError
      nil
    end
  end
  typecaster('Time') do |value|
    begin
      value.is_a?(String) && ::Time.zone ? ::Time.zone.parse(value) : value.to_time
    rescue ArgumentError
      nil
    end
  end
  typecaster('ActiveSupport::TimeZone') do |value|
    case value
    when ActiveSupport::TimeZone
      value
    when ::TZInfo::Timezone
      ActiveSupport::TimeZone[value.name]
    when String, Numeric, ActiveSupport::Duration
      value = begin
        Float(value)
      rescue
        value
      end
      ActiveSupport::TimeZone[value]
    end
  end
  typecaster('BigDecimal') do |value|
    next unless value
    begin
      ::BigDecimal.new Float(value).to_s
    rescue
      nil
    end
  end
  typecaster('Float') do |value|
    begin
      Float(value)
    rescue
      nil
    end
  end
  typecaster('Integer') do |value|
    begin
      Float(value).to_i
    rescue
      nil
    end
  end
  typecaster('Boolean') { |value| BOOLEAN_MAPPING[value] }
  typecaster('ActiveData::UUID') do |value|
    case value
    when UUIDTools::UUID
      ActiveData::UUID.parse_raw value.raw
    when ActiveData::UUID
      value
    when String
      ActiveData::UUID.parse_string value
    when Integer
      ActiveData::UUID.parse_int value
    end
  end

  persistence_adapter('ActiveRecord::Base') do |data_source, primary_key, scope_proc|
    ActiveData::Model::Associations::PersistenceAdapters::ActiveRecord.new(data_source, primary_key, scope_proc)
  end
end

ActiveSupport.on_load :active_record do
  require 'active_data/active_record/associations'
  require 'active_data/active_record/nested_attributes'

  include ActiveData::ActiveRecord::Associations
  include ActiveData::ActiveRecord::NestedAttributes
end
