# frozen_string_literal: true

# Shared RPN cell presentation (ADR-217, reused by the registries summary of
# ADR-219): the threshold band class and the integer-when-whole formatting.
module RpnRendering
  # Acceptable at or below the acceptable bound, unacceptable at or above the
  # unacceptable bound, caution between them (the ALARP band); a lone bound
  # leaves the rest of the range as caution. nil when no thresholds configured.
  def rpn_threshold_class(value, group)
    if group[:acceptable] && value <= group[:acceptable]
      'rpn_acceptable'
    elsif group[:unacceptable] && value >= group[:unacceptable]
      'rpn_unacceptable'
    elsif group[:acceptable] || group[:unacceptable]
      'rpn_caution'
    end
  end

  # Whole values print as integers (8 * 3 -> 24, not 24.0).
  def format_rpn(value)
    value == value.to_i ? value.to_i.to_s : value.to_s
  end
end
