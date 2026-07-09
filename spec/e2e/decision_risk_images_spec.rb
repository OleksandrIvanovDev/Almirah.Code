# frozen_string_literal: true

require_relative 'spec_helper'

# Covers the img-folder copy for decisions and risks introduced by ADR-227:
# every folder named img anywhere under decisions/ and risks/ is copied to the
# same relative location under build/, so the relative image references that
# the renderer already emits verbatim resolve in the rendered HTML.
RSpec.describe 'Decision and Risk Images', type: :aruba do
  context 'when img folders sit at every allowed decisions/ placement' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      # a record directly under decisions/ with its img folder beside it
      write_file('myproject/decisions/adr-001-root.md', <<~MD)
        ---
        title: "ADR-001: Root Record"
        ---

        # Context

        ![root sketch](img/root-sketch.png)
      MD
      write_file('myproject/decisions/img/root-sketch.png', 'root-png-bytes')
      # records sharing a release folder (with a space in its name) and one img folder
      write_file('myproject/decisions/release 1/adr-002-shared-a.md', <<~MD)
        ---
        title: "ADR-002: First Sharer"
        ---

        # Context

        ![shared diagram](img/shared-diagram.png)
      MD
      write_file('myproject/decisions/release 1/adr-003-shared-b.md', <<~MD)
        ---
        title: "ADR-003: Second Sharer"
        ---

        # Context

        ![shared diagram](img/shared-diagram.png)
      MD
      write_file('myproject/decisions/release 1/img/shared-diagram.png', 'shared-png-bytes')
      # a record in a deeper subfolder with its own img folder
      write_file('myproject/decisions/release 1/issues/issue-004-nested.md', <<~MD)
        ---
        title: "ISSUE-004: Nested Record"
        ---

        # Context

        ![screenshot](img/screenshot.png)
      MD
      write_file('myproject/decisions/release 1/issues/img/screenshot.png', 'issue-png-bytes')
      # an img folder with no record beside it — the copy rule is unconditional
      write_file('myproject/decisions/orphan/img/unreferenced.png', 'orphan-png-bytes')
      # an img folder's own subfolders and non-image files travel with it
      write_file('myproject/decisions/img/nested/deep.png', 'deep-png-bytes')
      write_file('myproject/decisions/img/notes.txt', 'not an image')
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Copy every img folder under decisions/ to the same relative location under build/. >[SRS-176] </REQ>
    it 'copies the img folder beside a root-level record' do
      expect(File.read(expand_path('myproject/build/decisions/img/root-sketch.png'))).to eq('root-png-bytes')
    end

    # <REQ> Copy every img folder under decisions/ to the same relative location under build/. >[SRS-176] </REQ>
    it 'copies the img folder of a shared release folder, space in the name included' do
      copied = expand_path('myproject/build/decisions/release 1/img/shared-diagram.png')
      expect(File.read(copied)).to eq('shared-png-bytes')
    end

    # <REQ> Copy every img folder under decisions/ to the same relative location under build/. >[SRS-176] </REQ>
    it 'copies the img folder of a deeper nested subfolder' do
      copied = expand_path('myproject/build/decisions/release 1/issues/img/screenshot.png')
      expect(File.read(copied)).to eq('issue-png-bytes')
    end

    # <REQ> Every img folder is copied whether or not its files are referenced. >[SRS-176] </REQ>
    it 'copies an img folder that no record references' do
      expect(File.read(expand_path('myproject/build/decisions/orphan/img/unreferenced.png'))).to eq('orphan-png-bytes')
    end

    # <REQ> The img folder is copied whole, subfolders and non-image files included. >[SRS-176] </REQ>
    it 'copies img subfolders and non-image files' do
      expect(File.read(expand_path('myproject/build/decisions/img/nested/deep.png'))).to eq('deep-png-bytes')
      expect(File.read(expand_path('myproject/build/decisions/img/notes.txt'))).to eq('not an image')
    end

    # <REQ> Relative image references resolve in the rendered HTML. >[SRS-176] </REQ>
    it 'renders each record page with the relative src that the copied file satisfies' do
      { 'myproject/build/decisions/adr-001.html' => 'img/root-sketch.png',
        'myproject/build/decisions/release 1/adr-002.html' => 'img/shared-diagram.png',
        'myproject/build/decisions/release 1/adr-003.html' => 'img/shared-diagram.png',
        'myproject/build/decisions/release 1/issues/issue-004.html' => 'img/screenshot.png' }.each do |page, src|
        doc = Nokogiri::HTML(File.read(expand_path(page)))
        img = doc.at_css('img[src="' + src + '"]')
        expect(img).not_to be_nil, "expected #{page} to carry an img with src #{src}"
        expect(File.exist?(File.join(File.dirname(expand_path(page)), src))).to be true
      end
    end
  end

  context 'when img folders sit at every allowed risks/ placement' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      # a registry img folder, referenced from a record and from the preface
      write_file('myproject/risks/security/overview.md', <<~MD)
        ---
        title: "Security Risk Register"
        ---

        # Security Risks

        ![threat model](img/threat-model.png)
      MD
      write_file('myproject/risks/security/secr-001-injection.md', <<~MD)
        ---
        title: "SECR-001: Injection"
        ---

        # Description

        ![attack tree](img/attack-tree.png)
      MD
      write_file('myproject/risks/security/img/threat-model.png', 'threat-png-bytes')
      write_file('myproject/risks/security/img/attack-tree.png', 'attack-png-bytes')
      # a record nested deeper inside a registry with its own img folder
      write_file('myproject/risks/security/web/secr-002-xss.md', <<~MD)
        ---
        title: "SECR-002: XSS"
        ---

        # Description

        ![xss flow](img/xss-flow.png)
      MD
      write_file('myproject/risks/security/web/img/xss-flow.png', 'xss-png-bytes')
      # an img folder directly under risks/, belonging to no registry — still copied
      write_file('myproject/risks/img/registry-map.png', 'map-png-bytes')
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Copy every img folder under risks/ to the same relative location under build/. >[SRS-176] </REQ>
    it 'copies the registry img folder' do
      expect(File.read(expand_path('myproject/build/risks/security/img/threat-model.png'))).to eq('threat-png-bytes')
      expect(File.read(expand_path('myproject/build/risks/security/img/attack-tree.png'))).to eq('attack-png-bytes')
    end

    # <REQ> Copy every img folder under risks/ to the same relative location under build/. >[SRS-176] </REQ>
    it 'copies the img folder of a record nested deeper inside a registry' do
      expect(File.read(expand_path('myproject/build/risks/security/web/img/xss-flow.png'))).to eq('xss-png-bytes')
    end

    # <REQ> Every img folder under risks/ is copied, including one belonging to no registry. >[SRS-176] </REQ>
    it 'copies an img folder directly under risks/' do
      expect(File.read(expand_path('myproject/build/risks/img/registry-map.png'))).to eq('map-png-bytes')
    end

    # <REQ> A registry preface's relative image references resolve on the registry page. >[SRS-176] </REQ>
    it 'renders the registry page with the preface image resolving next to it' do
      doc = Nokogiri::HTML(File.read(expand_path('myproject/build/risks/security/overview.html')))
      img = doc.at_css('img[src="img/threat-model.png"]')
      expect(img).not_to be_nil
      expect(File.exist?(expand_path('myproject/build/risks/security/img/threat-model.png'))).to be true
    end

    # <REQ> Relative image references resolve in the rendered HTML. >[SRS-176] </REQ>
    it 'renders each risk record page with the relative src that the copied file satisfies' do
      { 'myproject/build/risks/security/secr-001.html' => 'img/attack-tree.png',
        'myproject/build/risks/security/web/secr-002.html' => 'img/xss-flow.png' }.each do |page, src|
        doc = Nokogiri::HTML(File.read(expand_path(page)))
        img = doc.at_css('img[src="' + src + '"]')
        expect(img).not_to be_nil, "expected #{page} to carry an img with src #{src}"
        expect(File.exist?(File.join(File.dirname(expand_path(page)), src))).to be true
      end
    end
  end

  context 'when the project has no img folders under decisions/ or risks/' do
    before do
      write_file('myproject/project.yml', "specifications:\n  input: []\n")
      write_file('myproject/decisions/adr-001-plain.md', <<~MD)
        ---
        title: "ADR-001: Plain Record"
        ---

        body
      MD
      write_file('myproject/risks/project/prjr-001-plain.md', <<~MD)
        ---
        title: "PRJR-001: Plain Risk"
        ---

        body
      MD
      # a plain FILE named img must not be mistaken for an image folder
      write_file('myproject/decisions/notes/img', 'a file, not a folder')
      run_command_and_stop('almirah please myproject')
    end

    # <REQ> Only folders named img are copied; nothing is created when none exist. >[SRS-176] </REQ>
    it 'creates no img folders under build/ and does not crash on a file named img' do
      expect(Dir.exist?(expand_path('myproject/build/decisions/img'))).to be false
      expect(Dir.exist?(expand_path('myproject/build/risks/project/img'))).to be false
      expect(File.exist?(expand_path('myproject/build/decisions/notes/img'))).to be false
      expect(File.exist?(expand_path('myproject/build/decisions/adr-001.html'))).to be true
      expect(File.exist?(expand_path('myproject/build/risks/project/prjr-001.html'))).to be true
    end
  end
end
