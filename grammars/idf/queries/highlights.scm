;; Tree-sitter highlights query for EnergyPlus IDF files.

; Comments — `!- ...` doc comments (field annotations) vs plain `! ...`.
(comment) @comment
((comment) @comment.doc
  (#match? @comment.doc "^!-"))

; Object types (`Zone`, `Building`, `BuildingSurface:Detailed`, ...)
(object type: (object_type) @type)

; Numbers (int, float, scientific notation `3.5E-6`)
(number) @number

; Reserved keyword values, case-insensitive (`Yes`, `No`, `Autosize`,
; `Autocalculate`, `Continuous`, `Discrete`, design-day kinds, ...)
((field_value) @keyword
  (#match? @keyword
    "^(?i)(yes|no|on|off|true|false|autocalculate|autosize|continuous|discrete|hourly|timestep|daily|monthly|runperiod|annual|summerdesignday|winterdesignday)$"))
((any_value) @keyword
  (#match? @keyword
    "^(?i)(yes|no|on|off|true|false|autocalculate|autosize|continuous|discrete|hourly|timestep|daily|monthly|runperiod|annual|summerdesignday|winterdesignday)$"))

; Alphanumeric field values (zone names, material names, ...) —
; must come after the keyword captures so keywords win.
(field_value) @attribute

; Punctuation
["," ";"] @punctuation.delimiter
