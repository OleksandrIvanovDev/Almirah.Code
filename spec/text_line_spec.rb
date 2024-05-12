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
end