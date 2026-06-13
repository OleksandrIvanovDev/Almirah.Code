# frozen_string_literal: true

# Guards the client-side rendering invariants required by ADR-188 / SRS-099:
# author-derived values must be inserted with safe DOM interfaces (never parsed
# as HTML), and URLs assigned in script must pass a scheme allow-list. These are
# static assertions on the shipped JS assets, since there is no browser harness.
SCRIPTS_DIR = File.expand_path('../lib/almirah/templates/scripts', __dir__)

describe 'Client-side rendering safety (ADR-188)' do
  # <REQ> Render author-derived values in client-side scripts via DOM text/attribute interfaces, not HTML parsing; the image caption is set as text. >[SRS-099] </REQ>
  describe 'image caption (main.js)' do
    let(:js) { File.read(File.join(SCRIPTS_DIR, 'main.js')) }

    it 'renders the author alt text as plain text, not HTML' do
      expect(js).to include('captionText.textContent = clicked.alt')
    end

    it 'does not assign the alt text via innerHTML' do
      expect(js).not_to match(/captionText\.innerHTML\s*=\s*clicked\.alt/)
    end
  end

  # <REQ> Search results use safe-DOM construction and admit a result link URL only when relative or using an allowed scheme. >[SRS-099] </REQ>
  describe 'search results (orama_search.js)' do
    let(:js) { File.read(File.join(SCRIPTS_DIR, 'orama_search.js')) }

    it 'inserts text content with createTextNode rather than innerHTML' do
      expect(js).to include('createTextNode(heading_text)')
      expect(js).not_to include('innerHTML')
    end

    it 'passes the heading URL through the scheme allow-list before assigning href' do
      expect(js).to include('a.href = safeUrl(heading_url)')
      expect(js).to include("ALLOWED_URL_SCHEMES = ['http', 'https', 'mailto']")
    end

    it 'does not leave the search link attached to document.body' do
      expect(js).not_to include('document.body.appendChild(a)')
    end
  end
end
