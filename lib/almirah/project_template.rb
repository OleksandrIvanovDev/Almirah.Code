# frozen_string_literal: true

require 'fileutils'

class ProjectTemplate # rubocop:disable Style/Documentation
  attr_accessor :project_root

  def initialize(project_name)
    path = File.join(Dir.pwd, project_name)
    Kernel.abort 'Suggested project folder already exists' if Dir.exist? path
    FileUtils.mkdir_p path
    @project_root = path
    create_requirements
    create_architecture
    create_tests
    create_test_runs
  end

  def create_requirements
    path = File.join(@project_root, 'specifications/req')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      ---
      title: Requirements Specification
      author: put your name here
      ---

      # Overview

      This is an example of software requirements specification.

      # Requirements

      This is a regular paragraph in the document.

      [REQ-001] This is a first requirement (controlled paragraph with ID equal to "REQ-001").

      [REQ-002] This is a second requirement.

      # Document Histrory

      | Revision | Description of changes | Date |
      |---|---|---|
      | A | Initial version | #{Time.now.strftime('%Y-%d-%m')} |

    EOS

    path = File.join(path, 'req.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end

  def create_architecture
    path = File.join(@project_root, 'specifications/arch')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      ---
      title: Architecture Specification
      author: put your name here
      ---

      # Overview

      This is an example of software architecture document.

      # System Overview

      This is a regular paragraph in the document.

      [ARCH-004] This is an architecture item that is related to requirement "REQ-001". >[REQ-001]

      [ARCH-002] This is a regular architecture item.

      # System Decomposition

      [ARCH-005] This is an architecture irem that is related to requirement "REQ-002". >[REQ-002]

      # Document Histrory

      | Revision | Description of changes | Date |
      |---|---|---|
      | A | Initial version | #{Time.now.strftime('%Y-%d-%m')} |

    EOS

    path = File.join(path, 'arch.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end

  def create_tests
    create_test_001
    create_test_002
    create_test_003
  end

  def create_test_001
    path = File.join(@project_root, 'tests/protocols/tp-001')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      # Test Case TP-001

      This is an example of test case for software requirement "REQ-001".

      # Test Summary

      | Param | Value |
      |---|---|
      | Software Version |  |
      | Tester Name | |
      | Date |  |

      # Test Procedure

      | Test Step # | Test Step Description | Result | Req. Id |
      |---|---|---|---|
      | 1 | Some preparation step |  |  |
      | 2 | Some verification step for requirement "REQ-001" | | >[REQ-001] |

    EOS

    path = File.join(path, 'tp-001.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end

  def create_test_002
    path = File.join(@project_root, 'tests/protocols/tp-002')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      # Test Case TP-002

      This is an example of test case for software requirement "REQ-002".

      # Test Summary

      | Param | Value |
      |---|---|
      | Software Version |  |
      | Tester Name | |
      | Date |  |

      # Test Procedure

      | Test Step # | Test Step Description | Result | Req. Id |
      |---|---|---|---|
      | 1 | Some preparation step |  |  |
      | 2 | Some verification step for requirement "REQ-002" | | >[REQ-002] |

    EOS

    path = File.join(path, 'tp-002.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end

  def create_test_003
    path = File.join(@project_root, 'tests/protocols/tq-001')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      # Test Case TQ-001

      This is an example of test case for software architecture item "ARCH-002".

      # Test Summary

      | Param | Value |
      |---|---|
      | Software Version |  |
      | Tester Name | |
      | Date |  |

      # Test Procedure

      | Test Step # | Test Step Description | Result | Req. Id |
      |---|---|---|---|
      | 1 | Some preparation step |  |  |
      | 2 | Some verification step for architecture item "ARCH-002" | | >[ARCH-002] |

    EOS

    path = File.join(path, 'tq-001.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end

  def create_test_runs
    run_test_001
    run_test_002
    run_test_003
  end

  def run_test_001
    path = File.join(@project_root, 'tests/runs/001/tp-001')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      # Test Case TP-001

      This is an example of test case for software requirement "REQ-001".

      # Test Summary

      | Param | Value |
      |---|---|
      | Software Version |  |
      | Tester Name | |
      | Date |  |

      # Test Procedure

      | Test Step # | Test Step Description | Result | Req. Id |
      |---|---|---|---|
      | 1 | Some preparation step | n/a |  |
      | 2 | Some verification step for requirement "REQ-001" | pass | >[REQ-001] |

    EOS

    path = File.join(path, 'tp-001.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end

  def run_test_002
    path = File.join(@project_root, 'tests/runs/001/tp-002')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      # Test Case TP-002

      This is an example of test case for software requirement "REQ-002".

      # Test Summary

      | Param | Value |
      |---|---|
      | Software Version |  |
      | Tester Name | |
      | Date |  |

      # Test Procedure

      | Test Step # | Test Step Description | Result | Req. Id |
      |---|---|---|---|
      | 1 | Some preparation step | n/a |  |
      | 2 | Some verification step for requirement "REQ-002" | fail | >[REQ-002] |

    EOS

    path = File.join(path, 'tp-002.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end

  def run_test_003
    path = File.join(@project_root, 'tests/runs/010/tq-002')
    FileUtils.mkdir_p path

    file_content = <<~EOS
      # Test Case TQ-001

      This is an example of test case for software architecture item "ARCH-002".

      # Test Summary

      | Param | Value |
      |---|---|
      | Software Version |  |
      | Tester Name | |
      | Date |  |

      # Test Procedure

      | Test Step # | Test Step Description | Result | Req. Id |
      |---|---|---|---|
      | 1 | Some preparation step | n/a |  |
      | 2 | Some verification step for architecture item "ARCH-002" | pass | >[ARCH-002] |

    EOS

    path = File.join(path, 'tq-001.md')
    file = File.open(path, 'w')
    file.puts file_content
    file.close
  end
end
