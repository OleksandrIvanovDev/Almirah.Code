# frozen_string_literal: true

require_relative 'spec_helper'
require 'webrick'
require 'ferrum'
require 'json'

# End-to-end test for in-page anchor navigation (ISSUE-189). The fixed #top_nav
# bar overlays the top of the scroll container; without scroll-padding-top on the
# root element, navigating to a fragment scrolls the target to y=0 where the bar
# hides it. This is a *computed scroll position* defect, so it can only be caught
# in a real browser: the test renders a tall document, serves build/ over HTTP,
# jumps to a heading's fragment in headless Chrome, and asserts the target lands
# below the bar's bottom edge rather than underneath it.
RSpec.describe 'In-page anchor navigation offset', type: :aruba do
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

    # A document tall enough to be scrollable, with a uniquely-named target
    # heading in the *middle*. There must be ample filler both before (so the jump
    # scrolls the page) and after (so the browser CAN place the target at y=0,
    # behind the bar — otherwise the target naturally lands below the bar at max
    # scroll and the test would pass even with the defect present).
    before_filler = (1..60).map { |n| "[REQ-#{format('%03d', n)}] Filler requirement before, number #{n}." }.join("\n\n")
    after_filler = (1..60).map { |n| "[REQ-#{format('%03d', n + 100)}] Filler requirement after, number #{n}." }.join("\n\n")
    write_file('myproject/specifications/req/req.md', <<~MD)
      ---
      title: "Anchored Spec"
      ---

      # Top

      #{before_filler}

      ## Zorblax

      [REQ-999] The anchored target requirement.

      #{after_filler}
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
      window_size: [1200, 600], # > body min-width: 900px; short enough to force scrolling
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

  def doc_url(fragment = nil)
    base = "http://127.0.0.1:#{@port}/specifications/req/req.html"
    fragment ? "#{base}##{fragment}" : base
  end

  # <REQ> In-page anchor navigation positions the target clear of the fixed top navigation bar >[SRS-100] </REQ>
  it 'positions the target below the fixed top navigation bar' do
    # First load the page to discover the generated anchor id for the target
    # heading (section-number + slug), rather than predicting the slug rules.
    @browser.go_to(doc_url)
    anchor = wait_until do
      @browser.evaluate(<<~JS)
        (() => {
          const anchors = Array.from(document.querySelectorAll('a[name]'));
          const hit = anchors.find(a => {
            const h = a.nextElementSibling;
            return h && /^H[1-6]$/.test(h.tagName) && /Zorblax/.test(h.textContent);
          });
          return hit ? hit.getAttribute('name') : null;
        })()
      JS
    end

    # Now navigate to the fragment and let the browser scroll to it.
    @browser.go_to(doc_url(anchor))

    metrics = wait_until do
      m = @browser.evaluate(<<~JS)
        (() => {
          const a = document.querySelector('a[name=#{anchor.to_json}]');
          const h = a && a.nextElementSibling;
          const nav = document.getElementById('top_nav');
          if (!h || !nav) return null;
          return {
            scrollY: window.scrollY,
            navBottom: nav.getBoundingClientRect().bottom,
            targetTop: h.getBoundingClientRect().top
          };
        })()
      JS
      # Wait until the page has actually scrolled to the target near the bottom.
      m && m['scrollY'] > 0 ? m : nil
    end

    aggregate_failures do
      # Sanity: the jump genuinely scrolled the page (otherwise the test is vacuous).
      expect(metrics['scrollY']).to be > 0
      # The defect: target top sits at/above the bar's bottom (hidden behind it).
      # The fix (scroll-padding-top) keeps the target fully below the bar.
      expect(metrics['targetTop']).to be >= metrics['navBottom']
    end
  end
end
