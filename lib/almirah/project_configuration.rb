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

  # Per-group planning start dates (ADR-211): a map from a decision group's
  # first-level folder name (under decisions/) to its start Date, read from
  # planning.groups as DD-MM-YYYY entries. Non-string or unparseable values are
  # dropped; empty when unset. A group absent from the map sequences after the
  # previous group rather than carrying a declared start.
  def get_group_start_dates
    value = planning_value('groups')
    return {} unless value.is_a?(Hash)

    value.each_with_object({}) do |(name, raw), acc|
      date = parse_planning_date(raw)
      acc[name.to_s] = date if date
    end
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

  # The ordered register-column list for a risk registry folder (ADR-216),
  # read from the risks: root — a list of { folder:, columns: } entries.
  # nil when the registry carries no configuration; such a registry renders
  # the implicit columns plus Status only.
  def get_risk_columns(folder)
    entry = risk_entry(folder)
    return nil unless entry.is_a?(Hash) && entry['columns'].is_a?(Array)

    entry['columns'].map(&:to_s)
  end

  # The named RPN groups of a risk registry folder (ADR-217), from the rpn:
  # list of its risks: entry, in configured order:
  # [{ name:, inputs: [..], acceptable:, unacceptable: }, ...]. Groups without
  # a name or a non-empty inputs list are dropped; a threshold bound that is
  # absent or not numeric is nil. Empty when the registry declares no groups.
  def get_risk_rpn_groups(folder)
    entry = risk_entry(folder)
    return [] unless entry.is_a?(Hash) && entry['rpn'].is_a?(Array)

    entry['rpn'].filter_map { |raw| risk_rpn_group(raw) }
  end

  def is_spec_db_shall_be_created
    if @parameters.key? 'output'
      @parameters['output'].each do |p|
        return true if p == 'specifications_db'
      end
    end
    false
  end

  # The risks: entry configuring a registry folder, or nil when absent.
  def risk_entry(folder)
    return nil unless @parameters.is_a?(Hash)

    entries = @parameters['risks']
    return nil unless entries.is_a?(Array)

    entries.find { |e| e.is_a?(Hash) && e['folder'].to_s == folder }
  end

  def risk_rpn_group(raw)
    return nil unless raw.is_a?(Hash)

    name = raw['name'].to_s
    inputs = raw['inputs']
    return nil if name.empty? || !inputs.is_a?(Array) || inputs.empty?

    thresholds = raw['thresholds'].is_a?(Hash) ? raw['thresholds'] : {}
    { name: name, inputs: inputs.map(&:to_s),
      acceptable: numeric_threshold(thresholds['acceptable']),
      unacceptable: numeric_threshold(thresholds['unacceptable']) }
  end

  def numeric_threshold(value)
    value.is_a?(Numeric) ? value : nil
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
