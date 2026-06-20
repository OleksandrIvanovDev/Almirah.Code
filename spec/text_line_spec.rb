describe 'TextLine' do
  it 'returns empty string' do
    obj = TextLine.new
    ret_val = obj.format_string('')
    expect(ret_val).to be_empty
  end

  it 'returns non-formatted string as is' do
    obj = TextLine.new
    ret_val = obj.format_string('Hello World!')
    expect(ret_val).to eq('Hello World!')
  end

  it 'returns *formatted* string in italic' do
    obj = TextLine.new
    ret_val = obj.format_string('*Hello World!*')
    expect(ret_val).to eq('<i>Hello World!</i>')
  end

  it 'returns **formatted** string in bold' do
    obj = TextLine.new
    ret_val = obj.format_string('**Hello World!**')
    expect(ret_val).to eq('<b>Hello World!</b>')
  end

  it 'returns ***formatted*** string in bold and italic' do
    obj = TextLine.new
    ret_val = obj.format_string('***Hello World!***')
    expect(ret_val).to eq('<b><i>Hello World!</i></b>')
  end

  it 'returns string with a part in parentheses as is' do
    obj = TextLine.new
    ret_val = obj.format_string('Hello (World)!')
    expect(ret_val).to eq('Hello (World)!')
  end

  it 'returns string with a part in square brackets as is' do
    obj = TextLine.new
    ret_val = obj.format_string('Hello [World]!')
    expect(ret_val).to eq('Hello [World]!')
  end

  it 'returns nested ***for**ma**tted*** string in mixed format' do
    obj = TextLine.new
    ret_val = obj.format_string('***Hello **World**!***')
    expect(ret_val).to eq('<b><i>Hello <b>World</b>!</i></b>')
  end

  it 'returns several ***formatted*** **formatted** *formatted* strings' do
    obj = TextLine.new
    ret_val = obj.format_string('***Hello*** **World** *!*')
    expect(ret_val).to eq('<b><i>Hello</i></b> <b>World</b> <i>!</i>')
  end

  it 'returns string with a [URL](formatted)' do
    obj = TextLine.new
    ret_val = obj.format_string('Hello [World](world_url)!')
    expect(ret_val).to eq('Hello <a target="_blank" rel="noopener" href="world_url" class="external">World</a>!')
  end

  it 'returns string with a [URL](formatted) wrapped in bold' do
    obj = TextLine.new
    ret_val = obj.format_string('**Hello [World](world_url)!**')
    expect(ret_val).to eq('<b>Hello <a target="_blank" rel="noopener" href="world_url" class="external">World</a>!</b>')
  end

  it 'returns string that consists of the [URL](formatted) only' do
    obj = TextLine.new
    ret_val = obj.format_string('[World](world_url)')
    expect(ret_val).to eq('<a target="_blank" rel="noopener" href="world_url" class="external">World</a>')
  end

  it 'returns string that consists of two [URL](formatted)' do
    obj = TextLine.new
    ret_val = obj.format_string('[World](world_url) [World2](world_url2)')
    expect(ret_val).to eq('<a target="_blank" rel="noopener" href="world_url" class="external">World</a>' +
    + ' <a target="_blank" rel="noopener" href="world_url2" class="external">World2</a>')
  end

  it 'returns string that consists of [text in square bracket] [URL](formatted) (text in parenthes)' do
    obj = TextLine.new
    ret_val = obj.format_string('[text in square bracket] [World](world_url) (text in parenthes)')
    expect(ret_val).to eq('[text in square bracket] <a target="_blank" rel="noopener" href="world_url" class="external">World</a> (text in parenthes)')
  end

  it 'returns string that consists of [text in square bracket][URL](formatted)(text in parenthes) with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string('[text in square bracket][World](world_url)(text in parenthes)')
    expect(ret_val).to eq('[text in square bracket]<a target="_blank" rel="noopener" href="world_url" class="external">World</a>(text in parenthes)')
  end

  it 'returns string that consists of (text in parenthes)[URL](formatted)[text in square bracket] with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string('(text in parenthes)[World](world_url)[text in square bracket]')
    expect(ret_val).to eq('(text in parenthes)<a target="_blank" rel="noopener" href="world_url" class="external">World</a>[text in square bracket]')
  end

  it 'returns string that consists of **(text in parenthes)[URL](formatted)** *[text in square bracket]*' do
    obj = TextLine.new
    ret_val = obj.format_string('**(text in parenthes)[World](world_url)** *[text in square bracket]*')
    expect(ret_val).to eq('<b>(text in parenthes)<a target="_blank" rel="noopener" href="world_url" class="external">World</a></b> <i>[text in square bracket]</i>')
  end

  it 'returns string that consists of **a***b* with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string('**a***b*')
    expect(ret_val).to eq('**a***b*')
  end

  it 'returns string that consists of *a***b* with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string('*a***b*')
    expect(ret_val).to eq('<i>a***b</i>')
  end

  it 'returns string that consists of **a**b* with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string('**a**b*')
    expect(ret_val).to eq('<b>a</b>b*')
  end

  it 'returns string that consists of ***a***b***c*** with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string('***a***b***c***')
    expect(ret_val).to eq('<b><i>a</i></b>b<b><i>c</i></b>')
  end

  it 'keeps a quoted asterisk "*" literal' do
    obj = TextLine.new
    ret_val = obj.format_string('only "*" markers were implemented')
    expect(ret_val).to eq('only &quot;*&quot; markers were implemented')
  end

  it 'keeps two quoted asterisks "*" "*" literal in the same line' do
    obj = TextLine.new
    ret_val = obj.format_string('both "*" and "-" are valid')
    expect(ret_val).to eq('both &quot;*&quot; and &quot;-&quot; are valid')
  end

  it 'still italicises a phrase whose first/last char is a quote: *"foo"*' do
    obj = TextLine.new
    ret_val = obj.format_string('*"foo"*')
    expect(ret_val).to eq('<i>&quot;foo&quot;</i>')
  end

  it 'keeps an asterisk surrounded by spaces literal' do
    obj = TextLine.new
    ret_val = obj.format_string('a * lone * star')
    expect(ret_val).to eq('a * lone * star')
  end

  it 'keeps a quoted double asterisk "**" literal' do
    obj = TextLine.new
    ret_val = obj.format_string('the "**" marker')
    expect(ret_val).to eq('the &quot;**&quot; marker')
  end

  it 'wraps a `code span` in <code class="inline"> tags' do
    obj = TextLine.new
    ret_val = obj.format_string('call `foo()` here')
    expect(ret_val).to eq('call <code class="inline">foo()</code> here')
  end

  it 'HTML-escapes < and > inside a code span' do
    obj = TextLine.new
    ret_val = obj.format_string('wrapped in `<i>...</i>`')
    expect(ret_val).to eq('wrapped in <code class="inline">&lt;i&gt;...&lt;/i&gt;</code>')
  end

  it 'HTML-escapes ampersands inside a code span' do
    obj = TextLine.new
    ret_val = obj.format_string('use `A & B` form')
    expect(ret_val).to eq('use <code class="inline">A &amp; B</code> form')
  end

  it 'leaves emphasis markers literal inside a code span' do
    obj = TextLine.new
    ret_val = obj.format_string('the `*foo*` marker')
    expect(ret_val).to eq('the <code class="inline">*foo*</code> marker')
  end

  it 'handles two code spans on the same line' do
    obj = TextLine.new
    ret_val = obj.format_string('`a` and `b`')
    expect(ret_val).to eq('<code class="inline">a</code> and <code class="inline">b</code>')
  end

  it 'leaves an unmatched single backtick as a literal character' do
    obj = TextLine.new
    ret_val = obj.format_string('this `is unfinished')
    expect(ret_val).to eq('this `is unfinished')
  end

  it 'still italicises text after a closed code span' do
    obj = TextLine.new
    ret_val = obj.format_string('`code` then *italic*')
    expect(ret_val).to eq('<code class="inline">code</code> then <i>italic</i>')
  end
end
