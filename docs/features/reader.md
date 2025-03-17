# Reader Module

## Overview

The Reader module is the core component of Koodo Reader, responsible for displaying and rendering EPUB books. It provides a complete reading experience with navigation, settings control, and interactive features.

## Architecture

The Reader is implemented as a class-based React component with the following structure:

```
src/pages/reader/
├── component.tsx       # Main Reader component implementation
├── index.tsx           # Container component connecting to Redux
├── index.css           # Reader-specific styles
└── interface.tsx       # TypeScript interfaces for props and state
```

## Key Features

### Book Rendering

The Reader uses the `Viewer` component to render EPUB content. The rendering process involves:

1. Parsing the EPUB file structure
2. Extracting HTML content
3. Rendering content with appropriate styles
4. Handling navigation between chapters

### Navigation

The Reader provides several navigation mechanisms:

- **Page-based navigation**: Forward/backward page turns
- **Chapter navigation**: Jump between book chapters
- **Table of Contents**: Structured navigation via book TOC
- **Progress-based navigation**: Jump to specific locations by percentage

### Panels

The Reader interface includes multiple panels that can be toggled:

- **Left Panel (Navigation)**: Table of contents and bookmarks
- **Right Panel (Settings)**: Display and reading preferences
- **Top Panel**: Book information and control options
- **Bottom Panel (Progress)**: Progress tracking and page information

### User Interface Elements

```tsx
render() {
  return (
    <div className="reader">
      <div className="background-container">
        <div className="background-blur"></div>
      </div>
      <div className="reader-content">
        <NavigationPanel />
        <Viewer />
        <SettingPanel />
      </div>
      <div className="reader-bottombar">
        <ProgressPanel />
      </div>
      <OperationPanel />
      <Tooltip id="tool-tip" className="tool-tip" />
      <Toaster />
    </div>
  );
}
```

### Configuration and Settings

The Reader uses the `ConfigService` to manage reading preferences including:

- Text size and font
- Theme and color scheme
- Reading mode (continuous scrolling or page-based)
- Display settings (margins, line spacing, etc.)

```tsx
// Example of reading configuration
const scale = ConfigService.getReaderConfig("scale");
const isTouch = ConfigService.getReaderConfig("isTouch") === "yes";
```

### Event Handling

The Reader implements several event handlers for user interaction:

- **Panel toggling**: Show/hide UI panels based on user actions
- **Touch/mouse handling**: Differentiate between touch and mouse inputs
- **Keyboard shortcuts**: Navigate and control the reader with keyboard
- **Scaling**: Adjust content size with scale controls

```tsx
// Example of panel handling
handleEnterReader = (position: string) => {
  isHovering = true;
  if (lock) return;
  lock = true;
  setTimeout(() => {
    lock = false;
  }, throttleTime);
  
  // Open appropriate panel based on position
  if (position === "left") {
    this.setState({ isOpenLeftPanel: true });
  } else if (position === "right") {
    this.setState({ isOpenRightPanel: true });
  } // ...and so on
};
```

### Progress Tracking

The Reader tracks reading progress through:

- Current location in the book
- Percentage completion
- Chapter information
- Reading time statistics

Progress information is persisted via the `DatabaseService` to allow readers to resume from their last position.

## Component Lifecycle

### Initialization

```tsx
constructor(props) {
  // Initialize state with configuration
  this.state = {
    isOpenRightPanel: ConfigService.getReaderConfig("isSettingLocked") === "yes",
    // Other state initialization
  };
}
```

### Setup

```tsx
componentDidMount() {
  // Set up background handling
  // Initialize timers
  // Set up event listeners
  
  // Start progress tracking
  this.tickTimer = setInterval(() => {
    if (this.props.currentBook.key) {
      this.setState({ time: this.state.time + 1 });
      // Update reading time statistics
    }
  }, 60000);
}
```

### Cleanup

```tsx
componentWillUnmount() {
  // Clear timers
  clearInterval(this.tickTimer);
  clearInterval(this.messageTimer);
  
  // Save reading progress
  // Remove event listeners
}
```

## Integration Points

### Redux Integration

The Reader connects to Redux for:

- Current book information
- Reading progress state
- User settings and preferences
- Navigation state

### External Services

The Reader integrates with:

- **DatabaseService**: Persistence for reading progress and settings
- **BookUtil**: Utilities for book parsing and handling
- **ConfigService**: Configuration management

## Performance Considerations

- **Throttling**: Prevents excessive rendering with throttled event handlers
- **Lazy loading**: Only loads content as needed for performance
- **Optimized rendering**: Uses efficient rendering techniques for smooth experience

## Customization

The Reader supports extensive customization through:

- Theme selection and custom color schemes
- Font family and size adjustments
- Layout controls (margins, line spacing, etc.)
- Reading mode preferences (page turning vs. scrolling)

## Potential Enhancement Areas

- **Performance optimization** for very large books
- **Improved rendering** for complex layouts and CSS
- **Enhanced touch controls** for mobile devices
- **Better accessibility** features for screen readers
- **More animation options** for page transitions 