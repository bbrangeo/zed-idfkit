/**
 * @file Tree-sitter grammar for EnergyPlus IDF files.
 *
 * IDF is a simple line-oriented data format:
 *  - comments start with `!` and run to end of line (often `!- ...` after a
 *    field). `!- ...` doc comments are distinguished from plain comments.
 *  - objects are an object type (possibly `Type:SubType`), followed by a
 *    comma-separated list of fields, terminated by `;`
 *  - fields are numbers (int / float / scientific), alphanumeric values,
 *    reserved keywords (`Yes`, `autosize`, ...), or empty (just a comma),
 *    with optional `!- comment` trailers
 *
 * The grammar is deliberately tolerant so that real-world (multi-megabyte)
 * IDF files parse without error nodes:
 *  - comments are `extras` (valid anywhere, never break a parse)
 *  - a catch-all string token handles any unexpected characters in values
 *  - the BOM is skipped
 */

module.exports = grammar({
  name: 'idf',

  extras: ($) => [/\s/, /\ufeff/, $.comment],

  rules: {
    source_file: ($) => repeat($.object),

    // `Type` or `Type:SubType`, e.g. `ZoneCapacitanceMultiplier:ResearchSpecial`.
    object: ($) =>
      seq(
        field('type', $.object_type),
        repeat(seq(optional($._value), ',')),
        optional($._value),
        ';',
      ),

    object_type: ($) => $.identifier,

    _value: ($) => choice(prec(1, $.number), $.field_value, $.any_value),

    // Note: reserved keyword values (`Yes`, `Autosize`, `Continuous`, ...) are
    // NOT a grammar node — they are highlighted via `#any-of?` predicates in
    // `queries/highlights.scm`. Tree-sitter lexical precedence would otherwise
    // match them as prefixes of real names (`No` in `NoSun`, `On` in `On/Off`).

    field_value: ($) => $.identifier,

    // Numbers: int, float, multi-dot versions (`9.4.0.002`) and scientific
    // notation (`3.5E-6`, `-0.4`). Floats are matched by the same token —
    // scientific notation takes priority over identifiers via `prec(1)`.
    number: ($) =>
      token(
        seq(
          optional('-'),
          repeat1(/\d/),
          repeat(seq('.', repeat1(/\d/))),
          optional(seq(/[eE]/, optional(/[+\-]/), repeat1(/\d/))),
        ),
      ),

    // Identifiers: letters, digits and the characters common in real IDF
    // names (`:` `-` `_` `.` `/` `\` `+` `*` `&` `%` `#` `(` `)` `$` `'` `"`
    // `=` `[` `]` `<` `>`), plus internal spaces so multi-word names like
    // `Any Number` or `Last Sunday in March` stay a single token. The token
    // never crosses `,` `;` `!` or a newline.
    identifier: ($) =>
      token(
        prec(
          0,
          seq(
            /[^!,;\n\s]/,
            repeat(/[^\n,;!]/),
          ),
        ),
      ),

    // Catch-all for any other characters that may appear inside a value:
    // starts/ends on a non-whitespace char, never crosses a `,` `;` `!` or
    // a newline, so a real file always parses without error nodes.
    any_value: ($) =>
      token(
        prec(
          -1,
          choice(
            /[^\s,;!][^\n,;!]*[^\s,;!]/,
            /[^\s,;!]/,
          ),
        ),
      ),

    // Plain `! ...` comments (block headers, inline notes). `!- ...` doc
    // comments are matched by the same token and distinguished in
    // `queries/highlights.scm` via a `#match?` predicate.
    comment: ($) => token(/![^\n]*/),
  },
});

