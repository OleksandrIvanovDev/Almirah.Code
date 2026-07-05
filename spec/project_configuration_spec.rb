# frozen_string_literal: true

require 'date'
require 'tmpdir'
require_relative '../lib/almirah/project_configuration'

# Unit coverage for the planning config: the ADR-196 hours_per_day value and the
# ADR-205 calendar start date and holidays.
RSpec.describe ProjectConfiguration do
  def config_for(yaml)
    dir = Dir.mktmpdir
    File.write(File.join(dir, 'project.yml'), yaml)
    described_class.new(dir)
  end

  describe '#get_hours_per_day' do
    it 'defaults to 8 when planning or the key is absent' do
      expect(config_for("specifications:\n  input: []\n").get_hours_per_day).to eq(8)
      expect(config_for("planning:\n  wip_limit: 2\n").get_hours_per_day).to eq(8)
    end

    it 'honours a positive configured value' do
      expect(config_for("planning:\n  hours_per_day: 6\n").get_hours_per_day).to eq(6)
    end

    it 'falls back to 8 for non-positive or non-numeric values' do
      expect(config_for("planning:\n  hours_per_day: 0\n").get_hours_per_day).to eq(8)
      expect(config_for("planning:\n  hours_per_day: -3\n").get_hours_per_day).to eq(8)
      expect(config_for("planning:\n  hours_per_day: nope\n").get_hours_per_day).to eq(8)
    end
  end

  describe '#get_start_date' do
    it 'parses a DD-MM-YYYY start_date' do
      expect(config_for("planning:\n  start_date: 22-06-2026\n").get_start_date).to eq(Date.new(2026, 6, 22))
    end

    it 'defaults to today when absent or unparseable' do
      expect(config_for("specifications:\n  input: []\n").get_start_date).to eq(Date.today)
      expect(config_for("planning:\n  start_date: nope\n").get_start_date).to eq(Date.today)
    end
  end

  describe '#get_holidays' do
    it 'parses a list of DD-MM-YYYY holidays and drops unparseable entries' do
      cfg = config_for("planning:\n  holidays:\n    - 25-12-2026\n    - nope\n    - 01-01-2027\n")
      expect(cfg.get_holidays).to eq([Date.new(2026, 12, 25), Date.new(2027, 1, 1)])
    end

    it 'returns an empty list when absent' do
      expect(config_for("planning:\n  wip_limit: 2\n").get_holidays).to eq([])
    end
  end

  describe '#get_group_start_dates' do
    it 'maps group folder names to their DD-MM-YYYY start dates' do
      cfg = config_for("planning:\n  groups:\n    release 0.4.0: 12-05-2026\n    release 0.4.3: 22-06-2026\n")
      expect(cfg.get_group_start_dates).to eq(
        'release 0.4.0' => Date.new(2026, 5, 12),
        'release 0.4.3' => Date.new(2026, 6, 22)
      )
    end

    it 'drops unparseable entries and keeps the rest' do
      cfg = config_for("planning:\n  groups:\n    good: 01-07-2026\n    bad: nope\n")
      expect(cfg.get_group_start_dates).to eq('good' => Date.new(2026, 7, 1))
    end

    it 'returns an empty map when absent or not a mapping' do
      expect(config_for("planning:\n  wip_limit: 2\n").get_group_start_dates).to eq({})
      expect(config_for("planning:\n  groups: nope\n").get_group_start_dates).to eq({})
    end
  end
end
