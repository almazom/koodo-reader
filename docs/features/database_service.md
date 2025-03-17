# Database Service

## Overview

The Database Service in Koodo Reader provides a persistent storage solution using IndexedDB. This service is responsible for storing and retrieving various application data including books, notes, bookmarks, reading progress, settings, and plugins.

## Architecture

The Database Service is implemented as a utility class in `src/utils/storage/databaseService.ts` and provides an abstraction layer over IndexedDB operations.

## Core Functionality

### Database Structure

The service manages several object stores (similar to tables in relational databases):

- **books**: Stores book metadata and content references
- **notes**: User notes and highlights
- **bookmarks**: User bookmarks
- **locations**: Reading progress for books
- **settings**: Application settings
- **plugins**: Plugin configurations
- **shelf**: Book organization in shelves
- **dict**: Dictionary search history

### CRUD Operations

The service provides methods for basic CRUD (Create, Read, Update, Delete) operations:

#### Adding Data

```tsx
/**
 * Add an item to a specified store
 * @param storeName The store to add the item to
 * @param item The item to add
 * @returns Promise that resolves when the item is added
 */
static add(storeName: string, item: any): Promise<any> {
  return new Promise((resolve, reject) => {
    // Implementation using IndexedDB
    const transaction = db.transaction([storeName], "readwrite");
    const store = transaction.objectStore(storeName);
    const request = store.add(item);
    
    request.onsuccess = () => {
      resolve(request.result);
    };
    
    request.onerror = (e) => {
      reject(e);
    };
  });
}
```

#### Retrieving Data

```tsx
/**
 * Get an item from a store by key
 * @param storeName The store to query
 * @param key The key to look up
 * @returns Promise that resolves with the item
 */
static get(storeName: string, key: string): Promise<any> {
  return new Promise((resolve, reject) => {
    // Implementation using IndexedDB
    const transaction = db.transaction([storeName], "readonly");
    const store = transaction.objectStore(storeName);
    const request = store.get(key);
    
    request.onsuccess = () => {
      resolve(request.result);
    };
    
    request.onerror = (e) => {
      reject(e);
    };
  });
}

/**
 * Get all items from a store
 * @param storeName The store to query
 * @returns Promise that resolves with all items
 */
static getAll(storeName: string): Promise<any[]> {
  return new Promise((resolve, reject) => {
    // Implementation using IndexedDB
    const transaction = db.transaction([storeName], "readonly");
    const store = transaction.objectStore(storeName);
    const request = store.getAll();
    
    request.onsuccess = () => {
      resolve(request.result);
    };
    
    request.onerror = (e) => {
      reject(e);
    };
  });
}
```

#### Updating Data

```tsx
/**
 * Update an item in a store
 * @param storeName The store containing the item
 * @param key The key of the item to update
 * @param updates The properties to update
 * @returns Promise that resolves when the update is complete
 */
static update(storeName: string, key: string, updates: any): Promise<any> {
  return new Promise((resolve, reject) => {
    // Implementation using IndexedDB
    this.get(storeName, key).then((item) => {
      if (!item) {
        reject(new Error("Item not found"));
        return;
      }
      
      const transaction = db.transaction([storeName], "readwrite");
      const store = transaction.objectStore(storeName);
      
      // Apply updates to the item
      Object.assign(item, updates);
      
      const request = store.put(item);
      
      request.onsuccess = () => {
        resolve(request.result);
      };
      
      request.onerror = (e) => {
        reject(e);
      };
    });
  });
}
```

#### Deleting Data

```tsx
/**
 * Delete an item from a store
 * @param storeName The store containing the item
 * @param key The key of the item to delete
 * @returns Promise that resolves when the item is deleted
 */
static delete(storeName: string, key: string): Promise<void> {
  return new Promise((resolve, reject) => {
    // Implementation using IndexedDB
    const transaction = db.transaction([storeName], "readwrite");
    const store = transaction.objectStore(storeName);
    const request = store.delete(key);
    
    request.onsuccess = () => {
      resolve();
    };
    
    request.onerror = (e) => {
      reject(e);
    };
  });
}
```

### Specialized Operations

The service also provides specialized methods for common operations:

```tsx
/**
 * Find items in a store by index
 * @param storeName The store to search
 * @param indexName The index to use
 * @param indexValue The value to search for
 * @returns Promise that resolves with matching items
 */
static findBy(storeName: string, indexName: string, indexValue: any): Promise<any[]> {
  return new Promise((resolve, reject) => {
    // Implementation using IndexedDB indexes
    const transaction = db.transaction([storeName], "readonly");
    const store = transaction.objectStore(storeName);
    const index = store.index(indexName);
    const request = index.getAll(indexValue);
    
    request.onsuccess = () => {
      resolve(request.result);
    };
    
    request.onerror = (e) => {
      reject(e);
    };
  });
}

/**
 * Clear all data from a store
 * @param storeName The store to clear
 * @returns Promise that resolves when the store is cleared
 */
static clear(storeName: string): Promise<void> {
  return new Promise((resolve, reject) => {
    // Implementation using IndexedDB
    const transaction = db.transaction([storeName], "readwrite");
    const store = transaction.objectStore(storeName);
    const request = store.clear();
    
    request.onsuccess = () => {
      resolve();
    };
    
    request.onerror = (e) => {
      reject(e);
    };
  });
}
```

## Database Initialization

The service handles database initialization, including schema creation and versioning:

```tsx
/**
 * Initialize the database
 * @returns Promise that resolves when the database is ready
 */
static initDatabase(): Promise<void> {
  return new Promise((resolve, reject) => {
    // Open the database
    const request = indexedDB.open("koodo-reader", DB_VERSION);
    
    // Handle database upgrade (schema changes)
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      
      // Create object stores if they don't exist
      if (!db.objectStoreNames.contains("books")) {
        const bookStore = db.createObjectStore("books", { keyPath: "key" });
        bookStore.createIndex("md5", "md5", { unique: true });
        // Other indexes...
      }
      
      // Create other stores with their indexes
      // ...
    };
    
    request.onsuccess = (event) => {
      db = event.target.result;
      resolve();
    };
    
    request.onerror = (event) => {
      reject(event);
    };
  });
}
```

## Integration with Application Components

The Database Service is used throughout the application:

### In Redux Actions

```tsx
// Example of using DatabaseService in Redux actions
export const handleFetchBooks = () => {
  return (dispatch: Dispatch) => {
    DatabaseService.getAll("books").then((results: Book[]) => {
      dispatch({ type: FETCH_BOOKS, payload: results });
    });
  };
};
```

### In Component Methods

```tsx
// Example of using DatabaseService in a component
saveReadingProgress = (locationData) => {
  DatabaseService.update("locations", this.props.currentBook.key, {
    chapter: currentChapter,
    percentage: currentPercentage,
    chapterProgress: chapterProgressData
  });
};
```

## Performance Considerations

The Database Service implements several optimizations:

- **Batched Operations**: For multiple related operations
- **Optimized Queries**: Using indexes for faster lookups
- **Lazy Loading**: Only loading necessary data
- **Transaction Management**: Proper use of IndexedDB transactions

```tsx
// Example of a batched operation
static addMultiple(storeName: string, items: any[]): Promise<any> {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction([storeName], "readwrite");
    const store = transaction.objectStore(storeName);
    
    let completed = 0;
    const total = items.length;
    
    transaction.oncomplete = () => {
      resolve();
    };
    
    transaction.onerror = (e) => {
      reject(e);
    };
    
    // Add all items in a single transaction
    items.forEach((item) => {
      store.add(item);
    });
  });
}
```

## Data Migration

The service handles data migration during version upgrades:

```tsx
// Example of migration logic in onupgradeneeded
if (event.oldVersion < 2) {
  // Migrate from version 1 to 2
  // ...
}

if (event.oldVersion < 3) {
  // Migrate from version 2 to 3
  // ...
}
```

## Error Handling

The service implements robust error handling:

```tsx
// Example of error handling in a service method
static get(storeName: string, key: string): Promise<any> {
  return new Promise((resolve, reject) => {
    try {
      // Normal IndexedDB operation
      // ...
    } catch (error) {
      console.error(`Error getting ${key} from ${storeName}:`, error);
      reject(error);
    }
  });
}
```

## Export and Import

The service provides methods for data export and import:

```tsx
/**
 * Export all data as a JSON object
 * @returns Promise that resolves with exported data
 */
static exportData(): Promise<any> {
  // Implementation for exporting all data
}

/**
 * Import data from a JSON object
 * @param data The data to import
 * @returns Promise that resolves when import is complete
 */
static importData(data: any): Promise<void> {
  // Implementation for importing data
}
```

## Extending for LLM Integration

The Database Service can be extended to support LLM-related data:

### New Object Store for LLM Results

```tsx
// In database initialization
if (!db.objectStoreNames.contains("llm_results")) {
  const llmStore = db.createObjectStore("llm_results", { keyPath: "id" });
  llmStore.createIndex("book_key", "book_key", { unique: false });
  llmStore.createIndex("chapter", "chapter", { unique: false });
  llmStore.createIndex("type", "type", { unique: false });
  llmStore.createIndex("timestamp", "timestamp", { unique: false });
}
```

### Data Structure for LLM Results

```tsx
interface LLMResult {
  id: string;           // Unique identifier
  book_key: string;     // Reference to the book
  chapter?: string;     // Chapter reference (if applicable)
  text_section?: string; // Text section reference (if applicable)
  type: string;         // Type of result (summary, qa, podcast)
  result: string;       // The LLM-generated content
  metadata: {           // Additional metadata
    model: string,      // Model used
    timestamp: number,  // When it was generated
    prompt: string,     // The prompt used
    parameters: any     // Model parameters used
  }
}
```

### Methods for LLM Data Management

```tsx
/**
 * Store an LLM result
 * @param result The LLM result to store
 * @returns Promise that resolves with the stored result ID
 */
static addLLMResult(result: LLMResult): Promise<string> {
  return this.add("llm_results", result);
}

/**
 * Get LLM results for a book
 * @param bookKey The book key to get results for
 * @param type Optional type filter
 * @returns Promise that resolves with matching results
 */
static getLLMResultsForBook(bookKey: string, type?: string): Promise<LLMResult[]> {
  if (type) {
    return this.findBy("llm_results", "book_key", bookKey).then((results) => {
      return results.filter((result) => result.type === type);
    });
  }
  return this.findBy("llm_results", "book_key", bookKey);
}

/**
 * Get LLM results for a specific chapter
 * @param bookKey The book key
 * @param chapter The chapter reference
 * @param type Optional type filter
 * @returns Promise that resolves with matching results
 */
static getLLMResultsForChapter(
  bookKey: string, 
  chapter: string, 
  type?: string
): Promise<LLMResult[]> {
  return this.findBy("llm_results", "book_key", bookKey).then((results) => {
    return results.filter((result) => {
      return result.chapter === chapter && (!type || result.type === type);
    });
  });
}
```

## Conclusion

The Database Service provides a robust foundation for data persistence in Koodo Reader. Its flexible design allows for extension to support new features like LLM integration, while maintaining performant access to application data. 