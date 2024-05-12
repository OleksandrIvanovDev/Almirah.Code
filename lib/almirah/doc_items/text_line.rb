class TextLineToken
    attr_accessor :value
    def initialize()
        @value = ""
    end
end

class ItalicToken < TextLineToken
    attr_accessor :value
    def initialize()
        @value = "*"
    end
end

class BoldToken < TextLineToken
    attr_accessor :value
    def initialize()
        @value = "**"
    end
end

class BoldAndItalicToken < TextLineToken
    attr_accessor :value
    def initialize()
        @value = "***"
    end
end

class TextLineParser
    attr_accessor :supported_tokens

    def initialize()
        @supported_tokens = Array.new
        @supported_tokens.append(BoldAndItalicToken.new)
        @supported_tokens.append(BoldToken.new)
        @supported_tokens.append(ItalicToken.new)
        @supported_tokens.append(TextLineToken.new)
    end

    def tokenize(str)
        result = Array.new
        sl = str.length
        si = 0
        while si < sl
            @supported_tokens.each do |t|
                tl = t.value.length
                if tl != 0  # literal is the last supported token in the list
                    projected_end_position = si+tl-1
                    if projected_end_position > sl
                        next
                    end
                    buf = str[si..projected_end_position]
                    if buf == t.value
                        result.append(t)
                        si = projected_end_position +1
                        break
                    end
                else
                    if (result.length > 0) and (result[-1].instance_of? TextLineToken)
                        literal = result[-1]
                        literal.value += str[si]
                    else
                        literal = TextLineToken.new
                        literal.value = str[si]
                        result.append(literal)
                    end
                    si += 1
                end
            end
        end
        return result
    end
end

class TextLineBuilderContext

    def italic(str)
        return str
    end

    def bold(str)
        return str
    end

    def bold_and_italic(str)
        return str
    end

    def link(link_text, link_url)
        return link_url
    end
end

class TextLineBuilder
    attr_accessor :builder_context

    def initialize(builder_context)
        @builder_context = builder_context
    end

    def restore(token_list)
        result = ""
        tl = token_list.length
        ti = 0
        while ti < tl
            if token_list[ti].instance_of? ItalicToken
                # try to find closing part
                tii = ti + 1
                while tii < tl
                    if token_list[tii].instance_of? ItalicToken
                        sub_list = token_list[(ti+1)..(tii-1)]
                        result += @builder_context.italic(restore(sub_list))
                        ti = tii +1
                        break
                    end 
                    tii += 1 
                end
            elsif token_list[ti].instance_of? BoldToken
                # try to find closing part
                tii = ti + 1
                while tii < tl
                    if token_list[tii].instance_of? BoldToken
                        sub_list = token_list[(ti+1)..(tii-1)]
                        result += @builder_context.bold(restore(sub_list))
                        ti = tii +1
                        break
                    end 
                    tii += 1 
                end
            elsif token_list[ti].instance_of? BoldAndItalicToken
                # try to find closing part
                tii = ti + 1
                while tii < tl
                    if token_list[tii].instance_of? BoldAndItalicToken
                        sub_list = token_list[(ti+1)..(tii-1)]
                        result += @builder_context.bold_and_italic(restore(sub_list))
                        ti = tii +1
                        break
                    end 
                    tii += 1 
                end
            elsif token_list[ti].instance_of? TextLineToken
                result += token_list[ti].value
                ti += 1 
            else
                ti += 1             
            end
        end
        return result
    end
end

class TextLine < TextLineBuilderContext

    @@lazy_doc_id_dict = Hash.new

    def self.add_lazy_doc_id(id)
        doc_id = id.to_s.downcase
        @@lazy_doc_id_dict[doc_id] = doc_id
    end

    def format_string(str)
        tlp = TextLineParser.new
        tlb = TextLineBuilder.new(self)
        tlb.restore(tlp.tokenize(str))
    end

    def format_string2(str)
        state = 'default'
        prev_state = 'default'
        result = ''
        stack = ''
        prev_c = ''
        link_text = ''
        link_url = ''
        str.each_char do |c|
            if c == '*'
                if state == 'default'
                    prev_state, state = change_state(c, state, 'first_asterisk_detected')

                elsif state == 'first_asterisk_detected'
                    prev_state, state = change_state(c, state, 'second_asterisk_detected')
                
                elsif state == 'second_asterisk_detected'
                    prev_state, state = change_state(c, state, 'third_asterisk_detected')
                
                elsif state == 'second_asterisk_detected'
                    prev_state, state = change_state(c, state, 'third_asterisk_detected')

                elsif state == 'italic_started'
                    prev_state, state = change_state(c, state, 'default')
                    result += italic(stack)

                elsif state == 'bold_started'
                    prev_state, state = change_state(c, state, 'first_asterisk_after_bold_detected')

                elsif state == 'first_asterisk_after_bold_detected'
                    prev_state, state = change_state(c, state, 'default')
                    result += bold(stack)

                elsif state == 'bold_and_italic_started'
                    prev_state, state = change_state(c, state, 'first_asterisk_after_bold_and_italic_detected')

                elsif state == 'first_asterisk_after_bold_and_italic_detected'
                    prev_state, state = change_state(c, state, 'second_asterisk_after_bold_and_italic_detected')

                elsif state == 'second_asterisk_after_bold_and_italic_detected'
                    prev_state, state = change_state(c, state, 'default')
                    result += bold_and_italic(stack)

                else
                end
            elsif c == '['
                if state == 'default'
                    prev_state, state = change_state(c, state, 'square_bracket_left_detected')
                else
                end
            elsif c == ']'
                if state == 'square_bracket_left_detected'
                    prev_state, state = change_state(c, state, 'default')
                    result += '[]'

                elsif state == 'link_text_started'
                    prev_state, state = change_state(c, state, 'square_bracket_right_detected')
                    link_text = stack

                else
                end
            elsif c == '('
                if state == 'square_bracket_right_detected'
                    prev_state, state = change_state(c, state, 'brace_left_detected')
                else
                    result += c
                end
            elsif c == ')'
                if state == 'brace_left_detected'
                    prev_state, state = change_state(c, state, 'default')
                    result += '()'

                elsif state == 'link_url_started'
                    prev_state, state = change_state(c, state, 'default')
                    link_url = stack
                    result += link(link_text, link_url)

                else
                    result += c
                end
            else
                if state == 'default'
                    result += c
                else
                    if state == 'first_asterisk_detected'
                        prev_state, state = change_state(c, state, 'italic_started')
                        stack = ''

                    elsif state == 'second_asterisk_detected'
                        prev_state, state = change_state(c, state, 'bold_started')
                        stack = ''

                    elsif state == 'third_asterisk_detected'
                        prev_state, state = change_state(c, state, 'bold_and_italic_started')
                        stack = ''
                    
                    elsif state == 'first_asterisk_after_bold_detected'
                        prev_state, state = change_state(c, state, 'bold_started')

                    elsif state == 'first_asterisk_after_bold_and_italic_detected'
                        prev_state, state = change_state(c, state, 'bold_and_italic_started')

                    elsif state == 'second_asterisk_after_bold_and_italic_detected'
                        prev_state, state = change_state(c, state, 'bold_and_italic_started')

                    elsif state == 'square_bracket_left_detected'
                        prev_state, state = change_state(c, state, 'link_text_started')
                        stack = ''

                    elsif state == 'square_bracket_right_detected'
                        prev_state, state = change_state(c, state, 'default')
                        result += stack + c
                        c = ''

                    elsif state == 'brace_left_detected'
                        prev_state, state = change_state(c, state, 'link_url_started')
                        stack = ''

                    else
                    end
                    stack += c
                end
            end
            prev_c = c
        end
        return result
    end

    def change_state(c, cur_state, new_state)
        # puts "[#{c}] Transition: #{cur_state} --> #{new_state}"
        return cur_state, new_state
    end

    def italic(str)
        "<i>#{str}</i>"
    end

    def bold(str)
        "<b>#{str}</b>"
    end

    def bold_and_italic(str)
        "<b><i>#{str}</i></b>"
    end

    def link(link_text, link_url)

        # define default result first
        result = "<a target=\"_blank\" rel=\"noopener\" href=\"#{link_url}\" class=\"external\">#{link_text}</a>"

        lazy_doc_id, anchor = nil, nil

        if res = /(\w+)[.]md$/.match(link_url)          #link
            lazy_doc_id = res[1].to_s.downcase

        elsif res = /(\w*)[.]md(#.*)$/.match(link_url)  # link with anchor
            if res && res.length > 2
                lazy_doc_id = res[1]
                anchor = res[2]
            end
        end

        if lazy_doc_id
            if @@lazy_doc_id_dict.has_key?(lazy_doc_id)
                if anchor
                    result = "<a href=\".\\..\\#{lazy_doc_id}\\#{lazy_doc_id}.html#{anchor}\" class=\"external\">#{link_text}</a>"
                else
                    result = "<a href=\".\\..\\#{lazy_doc_id}\\#{lazy_doc_id}.html\" class=\"external\">#{link_text}</a>"
                end
            end
        end
        return result
    end
end