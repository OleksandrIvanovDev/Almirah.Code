# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the concise console progress output introduced by ADR-184.
# Each example is linked to the requirement it verifies via a
# "<REQ> ... >[SRS-NNN] </REQ>" traceability comment.
RSpec.describe 'almirah please console output', type: :aruba do
  def stdout_lines
    last_command_started.stdout.each_line.map(&:chomp).reject(&:empty?)
  end

  def write_minimal_project(dir)
    write_file("#{dir}project.yml", <<~YML)
      specifications:
        input: []
    YML
    write_file("#{dir}specifications/req/req.md", <<~MD)
      # Requirements

      [REQ-001] A first requirement.
    MD
  end

  context 'when processing a project in a sub-directory' do
    before do
      write_minimal_project('myproject/')
      run_command_and_stop('almirah please myproject', fail_on_error: false)
    end

    # <REQ> emits a per-phase progress summary line pairing a label with a count >[SRS-079] </REQ>
    it 'prints one per-phase progress line pairing a label with a count' do
      expect(last_command_started.stdout).to match(/^parsing specifications \.+ \d+ ok$/)
    end

    # <REQ> prints the generated index path as the final progress line >[SRS-080] </REQ>
    it 'prints the generated index path as the final progress line' do
      expect(stdout_lines.last).to match(%r{^rendering HTML \.+ .*build/index\.html$})
    end

    # <REQ> emits no ANSI escape codes when stdout is not an interactive terminal >[SRS-081] </REQ>
    it 'emits no ANSI escape codes when stdout is not a terminal' do
      expect(last_command_started.stdout).not_to include("\e[")
    end

    # <REQ> prints a separator-clean absolute index path for a non-current directory >[SRS-082] </REQ>
    it 'prints an absolute, separator-clean index path' do
      out = last_command_started.stdout
      expect(stdout_lines.last).to match(%r{^rendering HTML \.+ /.+/myproject/build/index\.html$})
      expect(out).not_to include('myprojectbuild') # no missing separator
      expect(out).not_to match(%r{/myproject//build}) # no duplicated separator
    end
  end

  context 'when the project directory is given with a trailing slash' do
    before do
      write_minimal_project('myproject/')
      run_command_and_stop('almirah please myproject/', fail_on_error: false)
    end

    # <REQ> normalises a trailing-slash argument to a separator-clean absolute index path >[SRS-082] </REQ>
    it 'still prints a separator-clean absolute index path' do
      expect(stdout_lines.last).to match(%r{^rendering HTML \.+ /.+/myproject/build/index\.html$})
      expect(last_command_started.stdout).not_to match(%r{/myproject//build})
    end
  end

  context 'when the project directory resolves to the current directory' do
    before do
      write_minimal_project('')
      run_command_and_stop('almirah please .', fail_on_error: false)
    end

    # <REQ> prints the index path relative to the current directory when run against it >[SRS-082] </REQ>
    it 'prints the index path relative to the current directory' do
      expect(stdout_lines.last).to match(%r{^rendering HTML \.+ \./build/index\.html$})
    end
  end
end
