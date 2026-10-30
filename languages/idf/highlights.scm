;; Tree-sitter highlights query for EnergyPlus IDF files.
;;
;; Classification (most specific patterns last — later patterns win):
;;   object types  @type
;;   numbers       @number / @number.float (int vs float / scientific)
;;   booleans      @boolean (Yes, No, True, False)
;;   keywords      @keyword (Autosize, schedule kinds, ...)
;;   field values  @string (names, alphanumeric values)
;;   comments      @comment / @comment.doc

; Comments — `!- ...` doc comments (field annotations) vs plain `! ...`.
(comment) @comment
((comment) @comment.doc
  (#match? @comment.doc "^!-"))

; Object types (`Zone`, `Building`, `BuildingSurface:Detailed`, ...)
(object type: (object_type) @type)

; Numbers: integers (`0`, `25`), floats (`0.04`, `-0.4`), scientific
; notation (`3.5E-6`, `1.04e-005`) and multi-dot versions (`9.4.0.002`,
; highlighted as floats).
(number) @number
((number) @number.float
  (#match? @number.float "[.eE]"))

; Boolean values, case-insensitive (`Yes`, `No`, `True`, `False`).
((field_value) @boolean
  (#match? @boolean "^(?i)(yes|no|true|false)$"))
((any_value) @boolean
  (#match? @boolean "^(?i)(yes|no|true|false)$"))

; Reserved control keywords, case-insensitive (`Autosize`,
; `Autocalculate`, `Continuous`, `Discrete`, `On`/`Off`, schedule kinds, ...).
((field_value) @keyword
  (#match? @keyword
    "^(?i)(on|off|autocalculate|autosize|continuous|discrete|hourly|timestep|daily|monthly|runperiod|annual|summerdesignday|winterdesignday)$"))
((any_value) @keyword
  (#match? @keyword
    "^(?i)(on|off|autocalculate|autosize|continuous|discrete|hourly|timestep|daily|monthly|runperiod|annual|summerdesignday|winterdesignday)$"))

; Alphanumeric field values (zone names, material names, ...) —
; must come after the boolean/keyword captures so those win.
(field_value) @string

; Punctuation
["," ";"] @punctuation.delimiter
