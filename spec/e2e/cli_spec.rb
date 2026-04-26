# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'almirah CLI', type: :aruba do
  describe 'almirah please' do
    context 'when given a missing folder' do
      it 'exits with a non-zero status code' do
        run_command_and_stop('almirah please /nonexistent_folder_that_does_not_exist',
                             fail_on_error: false)
        expect(last_command_started).not_to have_exit_status(0)
      end
    end

    context 'when given a minimal valid project' do
      before do
        write_file('myproject/project.yml', <<~YML)
          specifications:
            input: []
        YML
        write_file('myproject/specifications/req/req.md', <<~MD)
          # Requirements

          [REQ-001] A first requirement.
        MD
        run_command_and_stop('almirah please myproject', fail_on_error: false)
      end

      it 'exits with status 0' do
        expect(last_command_started).to have_exit_status(0)
      end
    end
  end
end
