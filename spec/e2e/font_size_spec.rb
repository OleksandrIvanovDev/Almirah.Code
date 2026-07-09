# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the base font size setting (ADR-224): an optional font_size number in
# project.yml emitted as a root-element CSS custom property override on every
# rendered page, with headings, top menu and footer pinned in pixels in
# main.css so only the reading text and the navigation pane scale. Each example
# is linked to the requirement it verifies via a "<REQ> ... >[SRS-NNN] </REQ>" comment.
RSpec.describe 'base font size setting', type: :aruba do
  before do
    write_file('myproject/project.yml', <<~YML)
      font_size: 14
      specifications:
        input: []
      repositories:
        - name: myrepo
          path: mycode
    YML

    write_file('myproject/specifications/aaa/aaa.md', <<~MD)
      # AAA Specification

      [AAA-001] A requirement in AAA.
    MD

    write_file('mycode/example.rb', <<~RB)
      # <REQ> A tagged implementation line. >[AAA-001] </REQ>
      def example; end
    RB

    write_file('plainproject/project.yml', "specifications:\n  input: []\n")

    write_file('plainproject/specifications/aaa/aaa.md', <<~MD)
      # AAA Specification

      [AAA-001] A requirement in AAA.
    MD

    write_file('badproject/project.yml', <<~YML)
      font_size: fourteen
      specifications:
        input: []
    YML

    write_file('badproject/specifications/aaa/aaa.md', <<~MD)
      # AAA Specification

      [AAA-001] A requirement in AAA.
    MD

    run_command_and_stop('almirah please myproject', fail_on_error: false)
    run_command_and_stop('almirah please plainproject', fail_on_error: false)
    run_command_and_stop('almirah please badproject', fail_on_error: false)
  end

  let(:override) { '<style>:root { --almirah-font-size: 14px; }</style>' }

  def html(rel)
    File.read(expand_path(rel))
  end

  # <REQ> A configured font_size is emitted as the root custom property on a document page, after the main stylesheet. >[SRS-174] </REQ>
  it 'emits the override after the main.css link on a specification page' do
    page = html('myproject/build/specifications/aaa/aaa.html')
    expect(page).to include(override)
    expect(page.index(override)).to be > page.index('css/main.css')
  end

  # <REQ> Every rendered page carries the override, the Index page included. >[SRS-174] </REQ>
  it 'emits the override on the Index page' do
    expect(html('myproject/build/index.html')).to include(override)
  end

  # <REQ> Source-code pages, written by their own renderer, carry the same override. >[SRS-174] </REQ>
  it 'emits the override on a source file page' do
    expect(html('myproject/build/source_files/myrepo/example.rb.html')).to include(override)
  end

  # <REQ> Without the setting the pages render as before, with no override emitted. >[SRS-174] </REQ>
  it 'emits no override when font_size is absent' do
    expect(html('plainproject/build/specifications/aaa/aaa.html')).not_to include('--almirah-font-size')
    expect(html('plainproject/build/index.html')).not_to include('--almirah-font-size')
  end

  # <REQ> A non-numeric font_size is ignored rather than emitted. >[SRS-174] </REQ>
  it 'emits no override when font_size is not a number' do
    expect(html('badproject/build/specifications/aaa/aaa.html')).not_to include('--almirah-font-size')
  end

  # <REQ> The stylesheet takes the base size from the custom property with the 12px default, and pins headings, top menu and footer in pixels so they do not scale. >[SRS-174] </REQ>
  it 'ships main.css with the custom-property base size and pixel-pinned chrome' do
    css = html('myproject/build/css/main.css')
    expect(css).to include('font-size: var(--almirah-font-size, 12px);')
    expect(css).to include('font-size: 24px;')   # h1
    expect(css).to include('font-size: 21.6px;') # h2
    expect(css).to include('font-size: 18px;')   # h3 and top menu
    expect(css).to include('font-size: 10.8px;') # footer
    expect(css).not_to match(/font-size:\s*[0-9.]+em/)
  end
end
