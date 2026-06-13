# frozen_string_literal: true

# End-to-end coverage for ADR-188 / SRS-096..098: author-supplied Markdown is
# treated as untrusted and encoded for its HTML context, so script payloads
# planted in a source .md file are rendered inert in the generated site.
require_relative 'spec_helper'

RSpec.describe 'HTML output escaping (ADR-188)', type: :aruba do
  before do
    write_file('myproject/project.yml', <<~YML)
      specifications:
        input: []
    YML
    write_file('myproject/specifications/xss/xss.md', <<~'MD')
      # Document <script>alert('title')</script>

      ## Section <script>alert('h')</script>

      Paragraph with <script>alert('p')</script> and *emph* end.

      > Quote <script>alert('bq')</script> end.

      | Head <script>alert('th')</script> | B |
      |---|---|
      | Cell <script>alert('td')</script> | y |

      ```
      code <script>alert('cb')</script>
      ```

      Breakout [txt <img src=x onerror=alert('lt')> end](https://example.com).

      Bad link [click](javascript:alert('lh')) here.

      Good link [safe](https://example.com/safe) here.

      ![alt" onerror="alert('ia')](pic.png)

      ![js](javascript:alert('is'))

      ![diagram](img/d.svg)
    MD
    run_command_and_stop('almirah please myproject')
  end

  let(:html) { File.read(expand_path('myproject/build/specifications/xss/xss.html')) }

  # <REQ> HTML-escape author-supplied literal text rendered into element content (paragraph, heading, blockquote, table cell, fenced code block) so source markup is inert. >[SRS-096] </REQ>
  describe 'text content vectors' do
    it 'never emits an executable script element from any text context' do
      expect(html).not_to include('<script>alert')
    end

    it 'escapes a script element in paragraph text (SRS-096)' do
      expect(html).to include('&lt;script&gt;alert(&#39;p&#39;)&lt;/script&gt;')
    end

    it 'escapes a script element in heading text (SRS-096)' do
      expect(html).to include('&lt;script&gt;alert(&#39;h&#39;)&lt;/script&gt;')
    end

    it 'escapes a script element in blockquote text (SRS-096)' do
      expect(html).to include('&lt;script&gt;alert(&#39;bq&#39;)&lt;/script&gt;')
    end

    it 'escapes a script element in a table header cell (SRS-096)' do
      expect(html).to include('&lt;script&gt;alert(&#39;th&#39;)&lt;/script&gt;')
    end

    it 'escapes a script element in a table body cell (SRS-096)' do
      expect(html).to include('&lt;script&gt;alert(&#39;td&#39;)&lt;/script&gt;')
    end

    it 'escapes a script element in a fenced code block (SRS-096)' do
      expect(html).to include('&lt;script&gt;alert(&#39;cb&#39;)&lt;/script&gt;')
    end
  end

  # <REQ> Escape author-supplied values interpolated into HTML attributes (image src/alt, link href/text) so they cannot break out of the attribute. >[SRS-097] </REQ>
  describe 'attribute vectors' do
    it 'escapes an img element injected via link text (SRS-097)' do
      expect(html).not_to include('<img src=x onerror')
      expect(html).to include('&lt;img src=x onerror=alert(&#39;lt&#39;)&gt;')
    end

    it 'does not let image alt text break out of the attribute (SRS-097)' do
      expect(html).not_to include('onerror="alert')
      expect(html).to include('&quot; onerror=&quot;alert(&#39;ia&#39;)')
    end
  end

  # <REQ> Admit a link or image URL only when relative or using an allowed scheme (http/https/mailto); render any other scheme (javascript/data/vbscript) inert. >[SRS-098] </REQ>
  describe 'URL scheme allow-list' do
    it 'renders a javascript: link inert (SRS-098)' do
      expect(html).not_to include('javascript:alert')
    end

    it 'renders a javascript: image inert (SRS-098)' do
      expect(html).not_to include('src="javascript:')
    end
  end

  # <REQ> Legitimate formatting, allowed-scheme links, and relative images still render after escaping is applied. >[SRS-096], >[SRS-097], >[SRS-098] </REQ>
  describe 'legitimate content still renders' do
    it 'keeps an http(s) link' do
      expect(html).to include('href="https://example.com/safe"')
    end

    it 'keeps a relative image source' do
      expect(html).to include('src="img/d.svg"')
    end

    it 'keeps emphasis formatting' do
      expect(html).to include('<i>emph</i>')
    end
  end
end
