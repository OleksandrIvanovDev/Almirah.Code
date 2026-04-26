# frozen_string_literal: true

require 'aruba/rspec'

Aruba.configure do |config|
  config.exit_timeout = 30
  config.io_wait_timeout = 5
end
