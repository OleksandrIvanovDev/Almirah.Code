describe 'TextLine' do
  it 'returns empty string' do
    obj = TextLine.new
    ret_val = obj.format_string("")
    expect(ret_val).to be_empty
  end

  it 'returns non-formatted string as is' do
    obj = TextLine.new
    ret_val = obj.format_string("Hello World!")
    expect(ret_val).to eq("Hello World!")
  end

  it 'returns *formatted* string in italic' do
    obj = TextLine.new
    ret_val = obj.format_string("*Hello World!*")
    expect(ret_val).to eq("<i>Hello World!</i>")
  end

  it 'returns **formatted** string in bold' do
    obj = TextLine.new
    ret_val = obj.format_string("**Hello World!**")
    expect(ret_val).to eq("<b>Hello World!</b>")
  end

  it 'returns ***formatted*** string in bold and italic' do
    obj = TextLine.new
    ret_val = obj.format_string("***Hello World!***")
    expect(ret_val).to eq("<b><i>Hello World!</i></b>")
  end

  it 'returns string with a part in parentheses as is' do
    obj = TextLine.new
    ret_val = obj.format_string("Hello (World)!")
    expect(ret_val).to eq("Hello (World)!")
  end

  it 'returns string with a part in square brackets as is' do
    obj = TextLine.new
    ret_val = obj.format_string("Hello [World]!")
    expect(ret_val).to eq("Hello [World]!")
  end

  it 'returns nested ***for**ma**tted*** string in mixed format' do
    obj = TextLine.new
    ret_val = obj.format_string("***Hello **World**!***")
    expect(ret_val).to eq("<b><i>Hello <b>World</b>!</i></b>")
  end

  it 'returns several ***formatted*** **formatted** *formatted* strings' do
    obj = TextLine.new
    ret_val = obj.format_string("***Hello*** **World** *!*")
    expect(ret_val).to eq("<b><i>Hello</i></b> <b>World</b> <i>!</i>")
  end

  it 'returns string with a [URL](formatted)' do
    obj = TextLine.new
    ret_val = obj.format_string("Hello [World](world_url)!")
    expect(ret_val).to eq("Hello <a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a>!")
  end

  it 'returns string with a [URL](formatted) wrapped in bold' do
    obj = TextLine.new
    ret_val = obj.format_string("**Hello [World](world_url)!**")
    expect(ret_val).to eq("<b>Hello <a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a>!</b>")
  end

  it 'returns string that consists of the [URL](formatted) only' do
    obj = TextLine.new
    ret_val = obj.format_string("[World](world_url)")
    expect(ret_val).to eq("<a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a>")
  end

  it 'returns string that consists of two [URL](formatted)' do
    obj = TextLine.new
    ret_val = obj.format_string("[World](world_url) [World2](world_url2)")
    expect(ret_val).to eq("<a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a>" +
    + " <a target=\"_blank\" rel=\"noopener\" href=\"world_url2\" class=\"external\">World2</a>")
  end

  it 'returns string that consists of [text in square bracket] [URL](formatted) (text in parenthes)' do
    obj = TextLine.new
    ret_val = obj.format_string("[text in square bracket] [World](world_url) (text in parenthes)")
    expect(ret_val).to eq("[text in square bracket] <a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a> (text in parenthes)")
  end

  it 'returns string that consists of [text in square bracket][URL](formatted)(text in parenthes) with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string("[text in square bracket][World](world_url)(text in parenthes)")
    expect(ret_val).to eq("[text in square bracket]<a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a>(text in parenthes)")
  end

  it 'returns string that consists of (text in parenthes)[URL](formatted)[text in square bracket] with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string("(text in parenthes)[World](world_url)[text in square bracket]")
    expect(ret_val).to eq("(text in parenthes)<a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a>[text in square bracket]")
  end

  it 'returns string that consists of **(text in parenthes)[URL](formatted)** *[text in square bracket]*' do
    obj = TextLine.new
    ret_val = obj.format_string("**(text in parenthes)[World](world_url)** *[text in square bracket]*")
    expect(ret_val).to eq("<b>(text in parenthes)<a target=\"_blank\" rel=\"noopener\" href=\"world_url\" class=\"external\">World</a></b> <i>[text in square bracket]</i>")
  end

  it 'returns string that consists of **a***b* with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string("**a***b*")
    expect(ret_val).to eq("**a***b*")
  end

  it 'returns string that consists of *a***b* with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string("*a***b*")
    expect(ret_val).to eq("<i>a***b</i>")
  end

  it 'returns string that consists of **a**b* with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string("**a**b*")
    expect(ret_val).to eq("<b>a</b>b*")
  end

  it 'returns string that consists of ***a***b***c*** with no spaces' do
    obj = TextLine.new
    ret_val = obj.format_string("***a***b***c***")
    expect(ret_val).to eq("<b><i>a</i></b>b<b><i>c</i></b>")
  end
end