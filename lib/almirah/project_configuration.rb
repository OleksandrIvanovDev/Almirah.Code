require 'yaml'

class ProjectConfiguration
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
end
