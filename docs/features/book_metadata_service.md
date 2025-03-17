# Book Metadata Service

## Overview

The Book Metadata Service in Koodo Reader is responsible for extracting, managing, and storing metadata from various e-book formats. This metadata includes book titles, authors, publication dates, covers, and other bibliographic information that enhances the user experience and enables effective book organization and search.

## Architecture

The Book Metadata Service is implemented across several utility files, primarily in the `src/utils/fileOperation` directory:

- `bookUtil.ts`: Core functions for metadata extraction and processing
- `parseEpub.ts`: Functions specific to EPUB format metadata extraction
- `parsePdf.ts`: Functions specific to PDF format metadata extraction
- `parseMobi.ts`: Functions specific to MOBI/AZW format metadata extraction
- `parseTxt.ts`: Functions for basic metadata extraction from plain text files

## Core Functionality

### Metadata Extraction

The service extracts metadata from different e-book formats using specialized parsers:

#### EPUB Metadata Extraction

```tsx
/**
 * Extract metadata from EPUB files
 * @param file The EPUB file
 * @returns Promise that resolves with extracted metadata
 */
export const parseEpub = (file: any): Promise<BookModel> => {
  return new Promise((resolve, reject) => {
    // Use JSZip to extract the EPUB contents
    const zip = new JSZip();
    zip.loadAsync(file).then((contents) => {
      // Extract and parse the container.xml file to locate the OPF file
      contents.file("META-INF/container.xml").async("text").then((containerXml) => {
        const parser = new DOMParser();
        const containerDoc = parser.parseFromString(containerXml, "text/xml");
        const opfPath = containerDoc.querySelector("rootfile").getAttribute("full-path");
        
        // Extract and parse the OPF file to get metadata
        contents.file(opfPath).async("text").then((opfContent) => {
          const opfDoc = parser.parseFromString(opfContent, "text/xml");
          
          // Extract metadata fields
          const title = opfDoc.querySelector("metadata > dc\\:title")?.textContent || "Unknown Title";
          const author = opfDoc.querySelector("metadata > dc\\:creator")?.textContent || "Unknown Author";
          const publisher = opfDoc.querySelector("metadata > dc\\:publisher")?.textContent || "";
          const language = opfDoc.querySelector("metadata > dc\\:language")?.textContent || "";
          
          // Create book model with extracted metadata
          const bookModel = new BookModel({
            key: generateUUID(),
            name: title,
            author,
            publisher,
            language,
            // Additional fields...
          });
          
          // Extract cover image if available
          // ... cover extraction logic ...
          
          resolve(bookModel);
        });
      });
    }).catch((error) => {
      reject(error);
    });
  });
};
```

#### PDF Metadata Extraction

```tsx
/**
 * Extract metadata from PDF files
 * @param file The PDF file
 * @returns Promise that resolves with extracted metadata
 */
export const parsePdf = (file: any): Promise<BookModel> => {
  return new Promise((resolve, reject) => {
    // Use pdf.js to extract PDF metadata
    const fileReader = new FileReader();
    fileReader.onload = (event) => {
      const typedArray = new Uint8Array(event.target.result as ArrayBuffer);
      
      // Load the PDF document
      pdfjsLib.getDocument(typedArray).promise.then((pdf) => {
        // Get document metadata
        pdf.getMetadata().then((metadata) => {
          const info = metadata.info || {};
          
          // Create book model with extracted metadata
          const bookModel = new BookModel({
            key: generateUUID(),
            name: info.Title || file.name.replace(".pdf", ""),
            author: info.Author || "Unknown Author",
            publisher: info.Publisher || "",
            // Additional fields...
          });
          
          // Extract first page as cover
          pdf.getPage(1).then((page) => {
            // ... cover extraction logic ...
            resolve(bookModel);
          });
        }).catch(() => {
          // Fallback for PDFs without metadata
          const bookModel = new BookModel({
            key: generateUUID(),
            name: file.name.replace(".pdf", ""),
            author: "Unknown Author",
            // Additional fields...
          });
          resolve(bookModel);
        });
      }).catch((error) => {
        reject(error);
      });
    };
    fileReader.readAsArrayBuffer(file);
  });
};
```

### Unified Metadata Processing

The service provides a unified interface for metadata extraction regardless of file format:

```tsx
/**
 * Process book files and extract metadata
 * @param files Array of book files to process
 * @param callback Progress callback function
 * @returns Promise that resolves with processed book models
 */
export const processFiles = (files: File[], callback?: (progress: number) => void): Promise<BookModel[]> => {
  return new Promise((resolve, reject) => {
    const bookPromises: Promise<BookModel>[] = [];
    const totalFiles = files.length;
    let processedFiles = 0;
    
    // Process each file based on its type
    files.forEach((file) => {
      let bookPromise: Promise<BookModel>;
      
      // Determine file type and use appropriate parser
      if (file.name.endsWith(".epub")) {
        bookPromise = parseEpub(file);
      } else if (file.name.endsWith(".pdf")) {
        bookPromise = parsePdf(file);
      } else if (file.name.endsWith(".mobi") || file.name.endsWith(".azw3")) {
        bookPromise = parseMobi(file);
      } else if (file.name.endsWith(".txt")) {
        bookPromise = parseTxt(file);
      } else {
        // Handle unsupported formats
        bookPromise = Promise.resolve(new BookModel({
          key: generateUUID(),
          name: file.name,
          author: "Unknown Author",
          format: getFileExtension(file.name),
          // Additional fields...
        }));
      }
      
      // Handle progress tracking
      bookPromises.push(
        bookPromise.then((book) => {
          processedFiles++;
          if (callback) {
            callback(Math.floor((processedFiles / totalFiles) * 100));
          }
          return book;
        })
      );
    });
    
    // Resolve with all processed books
    Promise.all(bookPromises)
      .then((books) => resolve(books))
      .catch((error) => reject(error));
  });
};
```

### Cover Image Extraction

The service extracts cover images from e-books:

```tsx
/**
 * Extract cover image from EPUB
 * @param contents JSZip object with EPUB contents
 * @param opfDoc Parsed OPF document
 * @returns Promise that resolves with cover image data URL
 */
const extractEpubCover = (contents: JSZip, opfDoc: Document): Promise<string> => {
  return new Promise((resolve) => {
    // Try different methods to find the cover
    
    // Method 1: Look for cover in the manifest with 'cover' id
    const coverItem = opfDoc.querySelector("manifest > item[id='cover']");
    if (coverItem) {
      const coverPath = coverItem.getAttribute("href");
      contents.file(coverPath).async("blob").then((blob) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
      }).catch(() => resolve("")); // Fallback to empty string if extraction fails
      return;
    }
    
    // Method 2: Look for meta tag with name="cover"
    const coverMeta = opfDoc.querySelector("metadata > meta[name='cover']");
    if (coverMeta) {
      const coverId = coverMeta.getAttribute("content");
      const coverItemById = opfDoc.querySelector(`manifest > item[id='${coverId}']`);
      if (coverItemById) {
        // ... similar extraction logic ...
        return;
      }
    }
    
    // Method 3: Look for image with role="cover"
    // ... additional methods ...
    
    // Fallback if no cover is found
    resolve("");
  });
};
```

### Format Detection and Validation

The service includes utilities for detecting and validating e-book formats:

```tsx
/**
 * Check if a file is a supported e-book format
 * @param file The file to check
 * @returns Boolean indicating if the file is a supported format
 */
export const isSupportedFormat = (file: File): boolean => {
  const supportedFormats = [".epub", ".pdf", ".mobi", ".azw3", ".txt", ".fb2"];
  return supportedFormats.some((format) => file.name.toLowerCase().endsWith(format));
};

/**
 * Get the file extension
 * @param filename The filename
 * @returns The file extension
 */
export const getFileExtension = (filename: string): string => {
  return filename.slice(((filename.lastIndexOf(".") - 1) >>> 0) + 2);
};
```

## Integration with Book Model

The service integrates with the Book Model to structure the extracted metadata:

```tsx
/**
 * Book Model class
 */
export class BookModel {
  key: string;           // Unique identifier
  name: string;          // Book title
  author: string;        // Book author
  description?: string;  // Book description
  cover?: string;        // Cover image (data URL)
  format: string;        // File format
  publisher?: string;    // Publisher
  language?: string;     // Language code
  publishDate?: string;  // Publication date
  md5?: string;          // MD5 hash of the file content
  size?: number;         // File size in bytes
  path?: string;         // Local file path (desktop only)
  // Additional fields...
  
  constructor(options: Partial<BookModel>) {
    Object.assign(this, {
      key: generateUUID(),
      name: "Unknown Title",
      author: "Unknown Author",
      // Default values for other fields...
    }, options);
  }
}
```

## Integration with Application Components

The Book Metadata Service is used throughout the application:

### In the Book Import Process

```tsx
// Example of importing books in a component
importBooks = (files: File[]) => {
  // Show loading indicator
  this.setState({ importing: true, progress: 0 });
  
  // Process files to extract metadata
  processFiles(files, (progress) => {
    this.setState({ progress });
  }).then((books) => {
    // Store books in the database
    const addBookPromises = books.map((book) => {
      return DatabaseService.add("books", book);
    });
    
    Promise.all(addBookPromises).then(() => {
      // Update Redux store
      this.props.fetchBooks();
      this.setState({ importing: false });
    });
  }).catch((error) => {
    console.error("Error importing books:", error);
    this.setState({ importing: false });
  });
};
```

### In Redux Actions

```tsx
// Example of using metadata service in Redux actions
export const handleImportBooks = (files: File[]) => {
  return (dispatch: Dispatch) => {
    dispatch({ type: IMPORT_BOOKS_START });
    
    processFiles(files, (progress) => {
      dispatch({ type: IMPORT_BOOKS_PROGRESS, payload: progress });
    }).then((books) => {
      // Save to database
      const savePromises = books.map((book) => DatabaseService.add("books", book));
      
      Promise.all(savePromises).then(() => {
        dispatch({ type: IMPORT_BOOKS_SUCCESS, payload: books });
      });
    }).catch((error) => {
      dispatch({ type: IMPORT_BOOKS_FAILURE, payload: error });
    });
  };
};
```

## Performance Considerations

The Book Metadata Service implements several optimizations:

- **Parallel Processing**: Multiple books are processed concurrently
- **Progressive Loading**: Large files are processed in chunks
- **Lazy Cover Extraction**: Cover images are only extracted when needed
- **Caching**: Extracted metadata is cached to prevent redundant processing

```tsx
// Example of parallel processing with concurrency limit
export const processFilesWithConcurrency = (files: File[], maxConcurrent = 3): Promise<BookModel[]> => {
  return new Promise((resolve) => {
    const results: BookModel[] = [];
    let currentIndex = 0;
    let runningTasks = 0;
    
    const processNext = () => {
      if (currentIndex >= files.length && runningTasks === 0) {
        // All files are processed
        resolve(results);
        return;
      }
      
      while (runningTasks < maxConcurrent && currentIndex < files.length) {
        const fileIndex = currentIndex++;
        runningTasks++;
        
        // Process the file
        const file = files[fileIndex];
        let processPromise: Promise<BookModel>;
        
        if (file.name.endsWith(".epub")) {
          processPromise = parseEpub(file);
        } else if (file.name.endsWith(".pdf")) {
          processPromise = parsePdf(file);
        } else {
          // ... other formats ...
        }
        
        processPromise.then((book) => {
          results[fileIndex] = book;
          runningTasks--;
          processNext();
        }).catch(() => {
          // Handle error and create fallback book
          results[fileIndex] = new BookModel({
            key: generateUUID(),
            name: file.name,
            author: "Unknown Author",
            // ...
          });
          runningTasks--;
          processNext();
        });
      }
    };
    
    // Start processing
    processNext();
  });
};
```

## Error Handling

The service implements robust error handling for malformed e-books:

```tsx
/**
 * Safely extract EPUB metadata with fallback
 * @param file The EPUB file
 * @returns Promise that resolves with book model
 */
export const safeParseEpub = (file: File): Promise<BookModel> => {
  return new Promise((resolve) => {
    parseEpub(file).then((book) => {
      resolve(book);
    }).catch((error) => {
      console.error("Error parsing EPUB:", error);
      
      // Create fallback book with basic information
      const fallbackBook = new BookModel({
        key: generateUUID(),
        name: file.name.replace(".epub", ""),
        author: "Unknown Author",
        format: "epub",
        size: file.size,
        // Additional fields...
      });
      
      resolve(fallbackBook);
    });
  });
};
```

## Extending for LLM Integration

The Book Metadata Service can be extended to support LLM-related metadata:

### Enhanced Metadata Extraction for LLM Processing

```tsx
/**
 * Extract additional text content for LLM processing
 * @param file The book file
 * @param book The book model with basic metadata
 * @returns Promise that resolves with enhanced book model
 */
export const enhanceBookForLLM = (file: File, book: BookModel): Promise<BookModel> => {
  return new Promise((resolve, reject) => {
    if (file.name.endsWith(".epub")) {
      // For EPUB, extract chapter titles and text samples
      extractEpubChapters(file).then((chapters) => {
        // Enhance book model with chapter information
        const enhancedBook = {
          ...book,
          chapters,
          // Extract content summary for LLM context
          contentSummary: generateContentSummary(chapters)
        };
        resolve(enhancedBook);
      }).catch((error) => reject(error));
    } else if (file.name.endsWith(".pdf")) {
      // For PDF, extract table of contents and text samples
      extractPdfStructure(file).then((structure) => {
        // Enhance book model with structure information
        const enhancedBook = {
          ...book,
          chapters: structure.chapters,
          contentSummary: structure.summary
        };
        resolve(enhancedBook);
      }).catch((error) => reject(error));
    } else {
      // For other formats, provide basic enhancement
      resolve(book);
    }
  });
};

/**
 * Generate a content summary from chapters for LLM context
 * @param chapters Array of chapter information
 * @returns Content summary string
 */
const generateContentSummary = (chapters: any[]): string => {
  // Generate a summary of the book content based on chapter titles
  // and small samples of text from each chapter
  return chapters.map((chapter, index) => {
    return `Chapter ${index + 1}: ${chapter.title}\n${chapter.textSample.substring(0, 200)}...`;
  }).join("\n\n");
};
```

### Metadata for LLM Features

```tsx
/**
 * Prepare book metadata for LLM features
 * @param bookKey The book key
 * @returns Promise that resolves with LLM-ready metadata
 */
export const prepareBookForLLMFeatures = (bookKey: string): Promise<any> => {
  return new Promise((resolve, reject) => {
    // Get book from database
    DatabaseService.get("books", bookKey).then((book: BookModel) => {
      if (!book) {
        reject(new Error("Book not found"));
        return;
      }
      
      // Prepare metadata object for LLM processing
      const llmMetadata = {
        bookInfo: {
          title: book.name,
          author: book.author,
          publisher: book.publisher || "",
          language: book.language || "",
          description: book.description || ""
        },
        contentStructure: book.chapters?.map((chapter) => ({
          title: chapter.title,
          level: chapter.level || 1
        })) || [],
        // Additional context that might be useful for LLM
        genre: detectGenre(book),
        themes: extractThemes(book),
        readingLevel: estimateReadingLevel(book)
      };
      
      resolve(llmMetadata);
    }).catch((error) => reject(error));
  });
};

/**
 * Attempt to detect book genre based on metadata
 * @param book The book model
 * @returns Detected genre or empty string
 */
const detectGenre = (book: BookModel): string => {
  // Simple genre detection based on metadata
  // This could be enhanced with LLM-based genre detection
  // ...
  return "";
};

/**
 * Extract potential themes from book metadata
 * @param book The book model
 * @returns Array of possible themes
 */
const extractThemes = (book: BookModel): string[] => {
  // Extract themes from book description and content samples
  // This could be enhanced with LLM-based theme extraction
  // ...
  return [];
};

/**
 * Estimate the reading level of the book
 * @param book The book model
 * @returns Estimated reading level
 */
const estimateReadingLevel = (book: BookModel): string => {
  // Estimate reading level based on text samples
  // This could be enhanced with LLM-based reading level estimation
  // ...
  return "General";
};
```

## Conclusion

The Book Metadata Service provides a robust foundation for extracting, managing, and utilizing book metadata in Koodo Reader. Its flexible design allows for extension to support new features like LLM integration, while maintaining efficient metadata processing across multiple e-book formats. 