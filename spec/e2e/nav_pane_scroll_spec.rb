# frozen_string_literal: true

require_relative 'spec_helper'
require 'webrick'
require 'ferrum'
require 'json'

# End-to-end test for the left navigation pane scroll (ISSUE-190). #nav_pane is a
# fixed, full-height, internally-scrolling sections tree. With box-sizing:
# content-box, "height: 100%" plus its padding/border made the pane taller than
# the viewport, so its bottom (the end of the scroll range) fell below the fold
# and the last tree items could never be scrolled into view. This is a computed
# layout/scroll defect, so it can only be caught in a real browser: the test
# renders a document with a tall sections tree, opens the pane, scrolls it to the
# bottom, and asserts the last item lands inside the viewport.
RSpec.describe 'Left navigation pane scroll', type: :aruba do
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

  before do
    chrome = detect_chrome
    skip 'Chrome/Chromium not found (set BROWSER_PATH to enable this test)' unless chrome

    write_file('myproject/project.yml', <<~YML)
      specifications:
        input: []
    YML

    # Many headings produce a sections tree taller than the viewport, so the pane
    # must scroll internally and the last item is only reachable if the pane fits.
    sections = (1..80).map { |n| "## Section #{n}\n\n[REQ-#{format('%03d', n)}] Requirement #{n}." }.join("\n\n")
    write_file('myproject/specifications/req/req.md', <<~MD)
      ---
      title: "Tree Spec"
      ---

      #{sections}
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
      window_size: [1200, 600], # short enough that the tall tree must scroll
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

  # <REQ> The navigation pane scrolls so its entire sections tree is reachable >[SRS-101] </REQ>
  it 'scrolls to reveal the last item of a tall sections tree' do
    @browser.go_to("http://127.0.0.1:#{@port}/specifications/req/req.html")

    # Open the pane and scroll it fully to the bottom.
    @browser.evaluate(<<~JS)
      (() => {
        openNav();
        const pane = document.getElementById('nav_pane');
        pane.scrollTop = pane.scrollHeight;
      })()
    JS

    metrics = wait_until do
      m = @browser.evaluate(<<~JS)
        (() => {
          const pane = document.getElementById('nav_pane');
          const links = pane.querySelectorAll('a');
          if (!links.length) return null;
          const last = links[links.length - 1];
          const r = last.getBoundingClientRect();
          return {
            count: links.length,
            scrollTop: pane.scrollTop,
            maxScroll: pane.scrollHeight - pane.clientHeight,
            lastTop: r.top,
            lastBottom: r.bottom,
            viewportH: window.innerHeight,
            lastText: last.textContent
          };
        })()
      JS
      # Wait until the pane has been scrolled to (clamped) bottom.
      m && m['scrollTop'] >= m['maxScroll'] ? m : nil
    end

    aggregate_failures do
      # Sanity: the tree is genuinely taller than the pane (otherwise vacuous).
      expect(metrics['maxScroll']).to be > 0
      expect(metrics['lastText']).to include('Section 80')
      # The defect: at max scroll the last item still sits below the fold.
      # The fix keeps the pane within the viewport so the last item is visible.
      expect(metrics['lastBottom']).to be <= metrics['viewportH']
      expect(metrics['lastTop']).to be >= 0
    end
  end
end
