class TextLine

    def format_string(str)
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
                    prev_state = state
                    state = 'first_asterisk_detected'

                elsif state == 'first_asterisk_detected'
                    prev_state = state
                    state = 'second_asterisk_detected'
                
                elsif state == 'second_asterisk_detected'
                    prev_state = state
                    state = 'third_asterisk_detected'
                
                elsif state == 'second_asterisk_detected'
                    prev_state = state
                    state = 'third_asterisk_detected' 

                elsif state == 'italic_started'
                    prev_state = state
                    state = 'default'
                    result += italic(stack)

                elsif state == 'bold_started'
                    prev_state = state
                    state = 'first_asterisk_after_bold_detected'

                elsif state == 'first_asterisk_after_bold_detected'
                    prev_state = state
                    state = 'default'
                    result += bold(stack)

                elsif state == 'bold_and_italic_started'
                    prev_state = state
                    state = 'first_asterisk_after_bold_and_italic_detected'

                elsif state == 'first_asterisk_after_bold_and_italic_detected'
                    prev_state = state
                    state = 'second_asterisk_after_bold_and_italic_detected'

                elsif state == 'second_asterisk_after_bold_and_italic_detected'
                    prev_state = state
                    state = 'default'
                    result += bold_and_italic(stack)

                else
                end
            elsif c == '['
                if state == 'default'
                    prev_state = state
                    state = 'square_bracket_left_detected'
                else
                end
            elsif c == ']'
                if state == 'square_bracket_left_detected'
                    prev_state = state
                    state = 'default'
                    result += '[]'

                elsif state == 'link_text_started'
                    prev_state = state
                    state = 'square_bracket_right_detected'
                    link_text = stack

                else
                end
            elsif c == '('
                if state == 'square_bracket_right_detected'
                    prev_state = state
                    state = 'brace_left_detected'
                else
                end
            elsif c == ')'
                if state == 'brace_left_detected'
                    prev_state = state
                    state = 'default'
                    result += '()'

                elsif state == 'link_url_started'
                    prev_state = state
                    state = 'default'
                    link_url = stack
                    result += link(link_text, link_url)

                else
                end
            else
                if state == 'default'
                    result += c
                else
                    if state == 'first_asterisk_detected'
                        prev_state = state
                        state = 'italic_started'
                        stack = ''

                    elsif state == 'second_asterisk_detected'
                        prev_state = state
                        state = 'bold_started'
                        stack = ''

                    elsif state == 'third_asterisk_detected'
                        prev_state = state
                        state = 'bold_and_italic_started'
                        stack = ''
                    
                    elsif state == 'first_asterisk_after_bold_detected'
                        prev_state = state
                        state = 'bold_started'

                    elsif state == 'first_asterisk_after_bold_and_italic_detected'
                        prev_state = state
                        state = 'bold_and_italic_started'

                    elsif state == 'second_asterisk_after_bold_and_italic_detected'
                        prev_state = state
                        state = 'bold_and_italic_started'

                    elsif state == 'square_bracket_left_detected'
                        prev_state = state
                        state = 'link_text_started'
                        stack = ''

                    elsif state == 'square_bracket_right_detected'
                        prev_state = state
                        state = 'default'
                        result += stack + c
                        c = ''

                    elsif state == 'brace_left_detected'
                        prev_state = state
                        state = 'link_url_started'
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
        "<a href=\"#{link_url}\" class=\"external\">#{link_text}</a>"
    end
end