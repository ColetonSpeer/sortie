/// The user does not want dashes as punctuation in AI-written text. The
/// prompts say so; this is the safety net for what still slips through.
///
/// Em and en dashes between words become a comma; a double hyphen used as
/// a dash does too; a dash that ends a sentence is dropped. Hyphens inside
/// words (follow-up, on-site), in numbers and at the start of a list line
/// are left alone.
String dashFree(String s) {
  if (s.isEmpty) return s;
  var out = s;
  // "word — word", "word – word", "word -- word" (any spacing) → "word, word"
  out = out.replaceAllMapped(RegExp(r'(?<=\S)[ \t]*(?:—|–|--)[ \t]*(?=\S)'), (_) => ', ');
  // Spaced single hyphen used as a dash between words (not digits): "word - word"
  out = out.replaceAllMapped(RegExp(r'(?<=[^\s\d])[ \t]+-[ \t]+(?=[^\s\d])'), (_) => ', ');
  // A dash left dangling before a line break or the end
  out = out.replaceAll(RegExp(r'[ \t]*(?:—|–|--)[ \t]*(?=\n|$)'), '');
  // A dash opening a line of prose (not a list marker followed by a space)
  out = out.replaceAll(RegExp(r'(?<=^|\n)(?:—|–|--)[ \t]*'), '');
  // Tidy doubled commas produced by the above.
  out = out.replaceAll(RegExp(r',\s*,'), ',');
  out = out.replaceAll(RegExp(r',\s*(?=[.!?])'), '');
  return out;
}
