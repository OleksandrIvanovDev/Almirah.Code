# frozen_string_literal: true

require_relative 'spec_helper'

# Covers native cross-document links (ADR-186): Markdown relative links and
# [[wiki]] links across specifications, protocols, and decision records, plus
# anchors, broken-link reporting, and external-link passthrough. Each example is
# linked to the requirement it verifies via a "<REQ> ... >[SRS-NNN] </REQ>" comment.
RSpec.describe 'cross-document links', type: :aruba do
  before do
    write_file('myproject/project.yml', "specifications:\n  input: []\n")

    write_file('myproject/specifications/aaa/aaa.md', <<~MD)
      # AAA Specification

      [AAA-001] A requirement in AAA.

      Spec link: [see BBB](../bbb/bbb.md).
      Protocol link: [the protocol](../../tests/protocols/tp-700/tp-700.md).
      Broken file: [missing](./nonexistent.md).
      Broken wiki: [[does-not-exist]].
      External: [example](https://example.com).
      Mail: [mail](mailto:dev@example.com).
    MD

    write_file('myproject/specifications/bbb/bbb.md', <<~MD)
      # BBB Specification

      [BBB-001] A requirement in BBB.

      Deep link: [AAA one](../aaa/aaa.md#AAA-001).
    MD

    write_file('myproject/tests/protocols/tp-700/tp-700.md', <<~MD)
      # Test Protocol 700

      Back to [AAA](../../../specifications/aaa/aaa.md).
    MD

    write_file('myproject/decisions/relx/adr-700-first.md', <<~MD)
      ---
      title: "ADR-700: First"
      ---

      # Status

      |  | Date | Status |
      |:---:|---|---|
      | * | 01-01-2025 | Accepted |

      Decision link: [second](../rely/adr-701-second.md).
      Spec link: [AAA req](../../specifications/aaa/aaa.md).
      Wiki: [[adr-701]].
      Wiki alias: [[adr-701|the second decision]].
      Wiki anchor: [[aaa#AAA-001]].
    MD

    write_file('myproject/decisions/rely/adr-701-second.md', <<~MD)
      ---
      title: "ADR-701: Second"
      ---

      # Status

      |  | Date | Status |
      |:---:|---|---|
      | * | 01-01-2025 | Accepted |

      Back: [[adr-700]].
    MD

    run_command_and_stop('almirah please myproject', fail_on_error: false)
  end

  def page(rel)
    Nokogiri::HTML(File.read(expand_path("myproject/build/#{rel}")))
  end

  def link_by_text(doc, text)
    doc.css('a, span').find { |n| n.text.strip == text }
  end

  # <REQ> A Markdown spec-to-spec link resolves to the target's generated page. >[SRS-088] </REQ>
  it 'resolves a spec-to-spec Markdown link' do
    link = link_by_text(page('specifications/aaa/aaa.html'), 'see BBB')
    expect(link['href']).to eq('../bbb/bbb.html')
    expect(link['class']).to include('external')
  end

  # <REQ> A Markdown spec-to-protocol link resolves to the target's generated page. >[SRS-088] </REQ>
  it 'resolves a spec-to-protocol Markdown link' do
    link = link_by_text(page('specifications/aaa/aaa.html'), 'the protocol')
    expect(link['href']).to eq('../../tests/protocols/tp-700/tp-700.html')
  end

  # <REQ> A Markdown decision-to-spec link resolves to the target's generated page. >[SRS-088] </REQ>
  it 'resolves a decision-to-spec Markdown link' do
    link = link_by_text(page('decisions/relx/adr-700.html'), 'AAA req')
    expect(link['href']).to eq('../../specifications/aaa/aaa.html')
  end

  # <REQ> A decision-to-decision Markdown link maps the source filename to the id-named page. >[SRS-088] </REQ>
  it 'resolves a decision-to-decision Markdown link across folders to the id-named page' do
    link = link_by_text(page('decisions/relx/adr-700.html'), 'second')
    expect(link['href']).to eq('../rely/adr-701.html')
  end

  # <REQ> The source Markdown link stays a valid relative path on disk. >[SRS-089] </REQ>
  it 'keeps the source Markdown link navigable on disk' do
    src_dir = File.dirname(expand_path('myproject/specifications/aaa/aaa.md'))
    expect(File.exist?(File.expand_path('../bbb/bbb.md', src_dir))).to be true
  end

  # <REQ> A double-bracket wiki link resolves by unique id, independent of folder. >[SRS-090] </REQ>
  it 'resolves a [[wiki]] link by id regardless of folder' do
    link = link_by_text(page('decisions/relx/adr-700.html'), 'adr-701')
    expect(link['href']).to eq('../rely/adr-701.html')
  end

  # <REQ> A double-bracket link with an alias renders the alias as its visible text. >[SRS-091] </REQ>
  it 'renders the alias of a [[target|alias]] link' do
    link = link_by_text(page('decisions/relx/adr-700.html'), 'the second decision')
    expect(link).not_to be_nil
    expect(link['href']).to eq('../rely/adr-701.html')
  end

  # <REQ> An anchor in a double-bracket wiki link links to the fragment. >[SRS-092] </REQ>
  it 'resolves a [[target#anchor]] wiki link to the fragment' do
    link = link_by_text(page('decisions/relx/adr-700.html'), 'aaa#AAA-001')
    expect(link['href']).to eq('../../specifications/aaa/aaa.html#AAA-001')
  end

  # <REQ> An anchor in a Markdown link path links to the fragment. >[SRS-092] </REQ>
  it 'resolves a Markdown path#anchor link to the fragment' do
    link = link_by_text(page('specifications/bbb/bbb.html'), 'AAA one')
    expect(link['href']).to eq('../aaa/aaa.html#AAA-001')
  end

  # <REQ> The relative URL is computed from the linking page, with forward slashes. >[SRS-093] </REQ>
  it 'computes a forward-slash relative URL from the linking page' do
    link = link_by_text(page('decisions/relx/adr-700.html'), 'AAA req')
    expect(link['href']).to eq('../../specifications/aaa/aaa.html')
    expect(link['href']).not_to include('\\')
  end

  # <REQ> An unresolved cross-document link is rendered broken and reported. >[SRS-094] </REQ>
  it 'renders unresolved links as broken and reports them' do
    doc = page('specifications/aaa/aaa.html')
    broken_texts = doc.css('.broken_link').map { |n| n.text.strip }
    expect(broken_texts).to include('missing')        # broken Markdown link
    expect(broken_texts).to include('does-not-exist') # broken wiki link
    expect(last_command_started.output).to match(/broken links/)
    expect(last_command_started.output).to include('aaa')
  end

  # <REQ> External links (http, mailto) are left unchanged. >[SRS-095] </REQ>
  it 'leaves http and mailto links unchanged' do
    doc = page('specifications/aaa/aaa.html')
    ext = link_by_text(doc, 'example')
    expect(ext['href']).to eq('https://example.com')
    expect(ext['class'].to_s).not_to include('broken_link')
    mail = link_by_text(doc, 'mail')
    expect(mail['href']).to eq('mailto:dev@example.com')
  end
end
