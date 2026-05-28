# frozen_string_literal: true

require_relative 'spec_helper'
require 'webrick'
require 'ferrum'
require 'json'

# End-to-end test for the Orama client-side search on the rendered Index page
# (ISSUE-183). The search only works when the build is served over HTTP: the JS
# fetches the JSON DB (blocked under file://) and the search box is revealed only
# when document.URL includes 'http' (see templates/scripts/main.js). So this test
# renders a project, serves build/ with WEBrick, and drives the real index.html
# in headless Chrome via ferrum, hitting the live unpkg-hosted Orama bundle.
RSpec.describe 'Orama search on the Index page', type: :aruba do
  def detect_chrome
    bundled = [
      ENV.fetch('BROWSER_PATH', nil),
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/Applications/Chromium.app/Contents/MacOS/Chromium'
    ].compact.find { |p| File.executable?(p) }
    return bundled if bundled

    names = %w[google-chrome-stable google-chrome chromium chromium-browser chrome]
    names.map { |n| `command -v #{n} 2>/dev/null`.strip }.find { |r| !r.empty? }
  end

  def wait_until(timeout: 45, interval: 0.3)
    deadline = Time.now + timeout
    loop do
      result = yield
      return result if result
      raise "Timed out after #{timeout}s waiting for the browser condition" if Time.now > deadline

      sleep interval
    end
  end

  # Sets the search box value and fires the real keyup handler. Re-runnable so the
  # polling loop tolerates the module's async load (DB not yet indexed on early tries).
  def dispatch_search(term)
    @browser.evaluate(<<~JS)
      (() => {
        const e = document.getElementById('searchInput');
        if (!e) return false;
        e.value = #{term.to_json};
        e.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true }));
        return true;
      })()
    JS
  end

  def dropdown_text
    @browser.evaluate("(document.getElementById('search_dropdown') || {}).textContent || ''")
  end

  before do
    chrome = detect_chrome
    skip 'Chrome/Chromium not found (set BROWSER_PATH to enable this test)' unless chrome

    write_file('myproject/project.yml', <<~YML)
      specifications:
        input: []
    YML
    write_file('myproject/specifications/req/req.md', <<~MD)
      ---
      title: "Searchable Spec"
      ---

      # Requirements

      [REQ-001] The system shall index the unique token Zorblax for retrieval.
    MD
    run_command_and_stop('almirah please myproject')

    build_dir = expand_path('myproject/build')
    @server = WEBrick::HTTPServer.new(
      BindAddress: '127.0.0.1',
      Port: 0,
      DocumentRoot: build_dir,
      Logger: WEBrick::Log.new(File::NULL),
      AccessLog: []
    )
    @port = @server.listeners.first.addr[1]
    @server_thread = Thread.new { @server.start }

    @browser = Ferrum::Browser.new(
      headless: true,
      browser_path: chrome,
      browser_options: { 'no-sandbox' => nil, 'disable-dev-shm-usage' => nil },
      timeout: 60,
      process_timeout: 30
    )
  end

  after do
    @browser&.quit
    @server&.shutdown
    @server_thread&.join
  end

  # <REQ> Full-text search on the Index page returns matching specification content >[SRS-077] </REQ>
  # <REQ> Index page search indicates when there are no matches >[SRS-078] </REQ>
  it 'returns results for a known term and reports no matches otherwise' do
    @browser.go_to("http://127.0.0.1:#{@port}/index.html")

    # The http-only gate in main.js reveals the search box once the page is served.
    wait_until do
      @browser.evaluate(
        "(() => { const e = document.getElementById('searchInput'); " \
        "return !!e && getComputedStyle(e).display !== 'none'; })()"
      )
    end

    # Positive case: re-dispatch until the async module has loaded the DB and a hit renders.
    wait_until do
      dispatch_search('Zorblax')
      @browser.evaluate("!!document.querySelector('#search_dropdown a')")
    end

    item_count = @browser.evaluate("document.querySelectorAll('#search_dropdown .search-item').length")
    href = @browser.evaluate(
      "(() => { const a = document.querySelector('#search_dropdown a'); " \
      'return a ? a.getAttribute("href") : null; })()'
    )
    text = dropdown_text

    aggregate_failures do
      expect(item_count).to be >= 1
      expect(text).to include('Zorblax')          # snippet -> term was indexed and matched
      expect(text).to include('Searchable Spec')  # doc_title field rendered (ISSUE-183 rename)
      expect(href).to be_a(String).and(be_truthy)
      expect(href).not_to be_empty
    end

    # Negative case: a term that is not in the index shows the empty-state message.
    wait_until do
      dispatch_search('Qwxzplkno')
      dropdown_text.include?('There are no matches found')
    end
    expect(dropdown_text).to include('There are no matches found')
  end
end
