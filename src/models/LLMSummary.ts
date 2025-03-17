import { v4 as uuidv4 } from "uuid";

/**
 * Model representing an LLM-generated chapter summary
 */
export class LLMSummary {
  id: string;
  bookKey: string;
  chapterTitle: string;
  chapterIndex: number;
  content: string;
  model: string;
  timestamp: number;
  wordCount: number;

  /**
   * Constructor for LLMSummary
   * @param options Optional partial properties to initialize
   */
  constructor(options: Partial<LLMSummary> = {}) {
    this.id = options.id || uuidv4();
    this.bookKey = options.bookKey || "";
    this.chapterTitle = options.chapterTitle || "";
    this.chapterIndex = options.chapterIndex || 0;
    this.content = options.content || "";
    this.model = options.model || "";
    this.timestamp = options.timestamp || Date.now();
    this.wordCount = options.wordCount || 0;
  }
}

export default LLMSummary; 