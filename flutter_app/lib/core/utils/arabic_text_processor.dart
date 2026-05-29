import 'dart:core';

class ArabicTextProcessor {
  static String enhanceText(String input) {
    if (input.isEmpty) return input;

    String text = input;

    // 1. Clean spaces
    // Remove multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // 2. Improve punctuation
    // Ensure space after punctuation, not before
    text = text.replaceAll(RegExp(r'\s+([،.؟!:])'), r'$1');
    text = text.replaceAll(RegExp(r'([،.؟!:])(?=[^\s\d])'), r'$1 ');
    
    // Fix Arabic comma and question marks if English ones were used
    text = text.replaceAll(',', '،');
    text = text.replaceAll('?', '؟');

    // Remove repeated punctuation
    text = text.replaceAll(RegExp(r'([.?!])\1+'), r'$1');
    text = text.replaceAll(RegExp(r'([،])\1+'), r'$1');

    // 3. Improve paragraphs
    // Split into paragraphs based on dot followed by space and another word
    text = text.replaceAll(RegExp(r'\.\s+'), '.\n\n');

    // 4. Remove obvious redundant repeated words (e.g., "يعني يعني")
    text = text.replaceAllMapped(RegExp(r'\b(\w+)\s+\1\b', unicode: true), (match) => match.group(1)!);

    // 5. Basic dialect improvements / typo fixes (Examples)
    text = text.replaceAll(' اللي ', ' الذي ');
    text = text.replaceAll(' مش ', ' ليس ');
    text = text.replaceAll(' كدا ', ' هكذا ');
    text = text.replaceAll(' شنو ', ' ماذا ');

    return text.trim();
  }
}
