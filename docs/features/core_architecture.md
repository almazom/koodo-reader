# Koodo Reader - Core Architecture

## Overview

Koodo Reader is a modern EPUB reader application built with React and TypeScript. It follows a component-based architecture with Redux for state management. The application is designed to work both as a web application and a desktop application using Electron.

## Project Structure

The codebase is organized into the following main directories:

```
src/
├── assets/        # Static assets like images, fonts, and third-party libraries
├── components/    # Reusable UI components
├── constants/     # Application constants and configuration
├── containers/    # Container components (connected to Redux)
├── models/        # Data models for application entities
├── pages/         # Top-level page components
├── router/        # Application routing
├── store/         # Redux store configuration and state management
├── utils/         # Utility functions and services
```

## Key Technologies

- **React**: Frontend UI library
- **TypeScript**: Type-safe JavaScript
- **Redux**: State management
- **Electron**: Desktop application wrapper
- **i18next**: Internationalization
- **IndexedDB**: Client-side storage (via custom database service)

## Core Components

### Data Models

The application uses class-based models to represent entities:

- **Book**: Represents a book with metadata (title, author, format, etc.)
- **BookLocation**: Tracks reading progress and location within a book
- **Bookmark**: Stores user bookmarks within books
- **Note**: Manages user notes and highlights
- **HtmlBook**: Represents the parsed HTML content of a book
- **Plugin**: Defines plugin structures for extensibility

### State Management

Redux is used for application state management with the following structure:

- **Actions**: Defined in `src/store/actions/`
- **Reducers**: Organized in `src/store/reducers/`
- **Store**: Configured in `src/store/index.tsx`

The state is divided into logical slices such as:
- Book management
- Reader settings
- Progress tracking
- UI state

### Component Structure

Components typically follow this pattern:

1. **Container Component**: Connects to Redux and passes props
   ```tsx
   const mapStateToProps = (state: stateType) => {
     return {
       // state mappings
     };
   };
   
   const actionCreator = { /* actions */ };
   
   export default connect(
     mapStateToProps,
     actionCreator
   )(withTranslation()(Component));
   ```

2. **Presentational Component**: Contains the UI and logic
   ```tsx
   class Component extends React.Component<Props, State> {
     // Component implementation
   }
   ```

3. **Interface Definition**: Type definitions for props and state
   ```tsx
   export interface ComponentProps {
     // prop types
   }
   
   export interface ComponentState {
     // state types
   }
   ```

## Configuration System

The application uses a configuration service (`ConfigService`) to manage user preferences and settings. This service provides methods for getting and setting configuration values that persist across sessions.

## Database Service

The `DatabaseService` provides an abstraction over IndexedDB for client-side storage of:
- Books
- Reading progress
- Bookmarks
- Notes
- Settings

## Internationalization

The application supports multiple languages through the i18next library. Translation keys are defined in JSON files and accessed through the `withTranslation` HOC and `Trans` component.

## Electron Integration

The codebase is designed to work in both web and desktop environments, with conditional logic based on the `isElectron` flag to handle platform-specific functionality.

## Code Patterns

### Component Lifecycle

Components typically follow these lifecycle patterns:
- Constructor for initialization
- ComponentDidMount for setup and data fetching
- Render for UI display
- ComponentWillUnmount for cleanup

### Event Handling

Event handlers follow the naming convention of `handle[Action]`, for example:
- `handleChangeAudio`
- `handleStartSpeech`
- `handleLocation`

### Asynchronous Operations

Async operations are handled using async/await pattern:

```tsx
async handleRead() {
  try {
    // Async operation
  } catch (error) {
    // Error handling
  }
}
```

## Extension Points

The application provides several extension points:
- Plugin system for additional functionality
- Theme customization
- Reading mode configuration
- Format support for different book types 