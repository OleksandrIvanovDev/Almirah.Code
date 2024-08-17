# frozen_string_literal: true

require 'fileutils'

class ProjectUtility # rubocop:disable Style/Documentation
  attr_accessor :configuration

  def initialize(configuration)
    @configuration = configuration
  end

  def combine_protocols
    combine nil
  end

  def combine_run(run_id)
    combine run_id
  end

  private

  def combine(run_id) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    path = @configuration.project_root_directory
    dst_folder = "#{@configuration.project_root_directory}/build"
    FileUtils.mkdir_p(dst_folder)

    dst_file = "#{dst_folder}/combined.md"
    File.delete(dst_file) if File.exist?(dst_file)
    dst_f = File.open(dst_file, 'a')

    src_path = if run_id
                 unless Dir.exist? "#{path}/tests/runs/#{run_id}"
                   puts "\e[1m\e[31m Run #{run_id} folder does not exists"
                 end
                 "#{path}/tests/runs/#{run_id}/**/*.md"
               else
                 "#{path}/tests/protocols/**/*.md"
               end

    Dir.glob(src_path).sort.each do |f|
      puts "\e[35m #{f}"
      file = File.open(f)
      file_data = file.readlines
      file.close

      dst_f.puts file_data
      dst_f.puts # empty line
    end

    dst_f.close
  end
end
