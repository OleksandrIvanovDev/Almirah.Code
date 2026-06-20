# frozen_string_literal: true

require 'tmpdir'
require_relative '../lib/almirah/project_configuration'

# Unit coverage for the ADR-196 hours_per_day planning config: the default, a
# valid override, and the non-positive / wrong-type fallback.
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
end
