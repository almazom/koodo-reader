/**
 * Russian Syllable Counter
 * 
 * This utility counts syllables in Russian text, which is useful for
 * validating haiku structure (5-7-5 syllables).
 */

/**
 * Count syllables in a Russian word
 * In Russian, syllables generally correspond to vowel sounds.
 * 
 * @param word The Russian word
 * @returns Number of syllables
 */
export function countSyllablesInWord(word: string): number {
  // Russian vowels: а, е, ё, и, о, у, ы, э, ю, я
  const russianVowels = ['а', 'е', 'ё', 'и', 'о', 'у', 'ы', 'э', 'ю', 'я'];
  
  // Convert word to lowercase
  const lowerWord = word.toLowerCase();
  
  // Count vowels
  let count = 0;
  for (let i = 0; i < lowerWord.length; i++) {
    if (russianVowels.includes(lowerWord[i])) {
      count++;
    }
  }
  
  return count;
}

/**
 * Count syllables in a line of Russian text
 * 
 * @param line The line of Russian text
 * @returns Number of syllables
 */
export function countSyllablesInLine(line: string): number {
  // Split the line into words
  const words = line.trim().split(/\s+/);
  
  // Sum the syllables in each word
  return words.reduce((total, word) => total + countSyllablesInWord(word), 0);
}

/**
 * Check if a haiku follows the 5-7-5 syllable structure
 * 
 * @param haiku The haiku text (3 lines separated by newlines)
 * @returns Object containing validity and syllable counts
 */
export function validateRussianHaiku(haiku: string): {
  isValid: boolean;
  lineSyllables: number[];
  description: string;
} {
  // Split the haiku into lines
  const lines = haiku.trim().split('\n');
  
  // Check for three lines
  if (lines.length !== 3) {
    return {
      isValid: false,
      lineSyllables: lines.map(line => countSyllablesInLine(line)),
      description: `Haiku should have 3 lines, but found ${lines.length}`
    };
  }
  
  // Count syllables in each line
  const lineSyllables = lines.map(line => countSyllablesInLine(line));
  
  // Check for 5-7-5 pattern
  const isValid = lineSyllables[0] === 5 && lineSyllables[1] === 7 && lineSyllables[2] === 5;
  
  return {
    isValid,
    lineSyllables,
    description: isValid 
      ? 'Valid 5-7-5 haiku structure' 
      : `Expected 5-7-5 pattern, but found ${lineSyllables.join('-')}`
  };
} 