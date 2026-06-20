require 'yaml'
require 'date'

class ProjectConfiguration
  DEFAULT_WIP_LIMIT = 2
  DEFAULT_BUFFER_RATIO = 0.5
  DEFAULT_HOURS_PER_DAY = 8

  attr_accessor :project_root_directory, :parameters

  def initialize(path)
    @project_root_directory = File.expand_path(path)
    @parameters = {}
    load_project_file
  end

  def load_project_file
    @parameters = YAML.load_file(@project_root_directory + '/project.yml')
  rescue Psych::SyntaxError => e
    puts "YAML syntax error: #{e.message}"
  rescue Errno::ENOENT
    puts 'Project file not found: project.yml'
  end

  def get_design_inputs
    return @parameters['specifications']['input'] if (@parameters.key? 'specifications') and (@parameters['specifications'].key? 'input')

    []
  end

  def get_repositories
    return @parameters['repositories'] if @parameters.key? 'repositories'

    []
  end

  def get_wip_limit
    return DEFAULT_WIP_LIMIT unless @parameters.is_a?(Hash)

    planning = @parameters['planning']
    return DEFAULT_WIP_LIMIT unless planning.is_a?(Hash)

    value = planning['wip_limit']
    return DEFAULT_WIP_LIMIT unless value.is_a?(Integer) && value.positive?

    value
  end

  # The CCPM project-buffer ratio (ADR-195): a fraction in (0, 1] cutting the
  # aggregated chain safety. Absent or out-of-range falls back to the 0.5 default.
  def get_buffer_ratio
    return DEFAULT_BUFFER_RATIO unless @parameters.is_a?(Hash)

    planning = @parameters['planning']
    return DEFAULT_BUFFER_RATIO unless planning.is_a?(Hash)

    value = planning['buffer_ratio']
    return DEFAULT_BUFFER_RATIO unless value.is_a?(Numeric) && value.positive? && value <= 1

    value
  end

  # The calendar anchor for working day 1 (ADR-205), a Date parsed from a
  # DD-MM-YYYY planning.start_date. Absent or unparseable falls back to today,
  # so an unconfigured project still renders (a moving anchor).
  def get_start_date
    date = parse_planning_date(planning_value('start_date'))
    date || Date.today
  end

  # The non-working holiday dates (ADR-205) from planning.holidays, each a
  # DD-MM-YYYY entry; unparseable entries are dropped. Empty when unset.
  def get_holidays
    value = planning_value('holidays')
    return [] unless value.is_a?(Array)

    value.filter_map { |entry| parse_planning_date(entry) }
  end

  # Working hours per day (ADR-196): converts logged effort hours into the
  # working-day unit the estimates use. Absent or non-positive falls back to 8.
  def get_hours_per_day
    return DEFAULT_HOURS_PER_DAY unless @parameters.is_a?(Hash)

    planning = @parameters['planning']
    return DEFAULT_HOURS_PER_DAY unless planning.is_a?(Hash)

    value = planning['hours_per_day']
    return DEFAULT_HOURS_PER_DAY unless value.is_a?(Numeric) && value.positive?

    value
  end

  def is_spec_db_shall_be_created
    if @parameters.key? 'output'
      @parameters['output'].each do |p|
        return true if p == 'specifications_db'
      end
    end
    false
  end

  # A value under the planning: key, or nil when planning is absent.
  def planning_value(key)
    return nil unless @parameters.is_a?(Hash)

    planning = @parameters['planning']
    planning.is_a?(Hash) ? planning[key] : nil
  end

  # Parse a planning date that may already be a Date (YAML ISO form) or a
  # DD-MM-YYYY string; nil when neither.
  def parse_planning_date(value)
    return value if value.is_a?(Date)
    return nil unless value.is_a?(String)

    match = /\A(\d{2})-(\d{2})-(\d{4})\z/.match(value.strip)
    return nil unless match

    Date.new(match[3].to_i, match[2].to_i, match[1].to_i)
  rescue ArgumentError
    nil
  end
end
