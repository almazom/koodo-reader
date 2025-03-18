# AI Button and Side Drawer Integration Fix

## Current Status

The AI button and side drawer components have been implemented, but the drawer is not appearing correctly when the AI button is clicked. The UI elements shown in the sandbox example (`/home/almaz/koodo-reader/ai-button-sandbox/09-side-drawer.html`) are not being displayed properly in the main application.

## Component Analysis

1. **AIButton Component** (`src/components/aiButton/`)
   - Basic button implementation exists
   - Connected to Redux correctly
   - Button appears in the UI
   - Click handling is set up

2. **AIPanel Component** (`src/containers/panels/aiPanel/`)
   - Side drawer implementation exists
   - Connected to Redux correctly
   - UI matches the desired sandbox style
   - Component is included in the reader view

3. **Reader Component** (`src/pages/reader/component.tsx`)
   - AI Panel container is properly positioned
   - Transition animations are defined
   - Redux connection is established

4. **Redux Integration**
   - Action types defined
   - Action handlers implemented
   - Reducer case for `HANDLE_AI_DRAWER_OPEN` exists
   - Initial state includes `isAIDrawerOpen: false`

## Identified Issues

1. **Incorrect Button Wiring**
   - The "AI" button in the reader view may be manually implemented rather than using the AIButton component
   - The direct button in the reader view is positioned at `right: 70px` which differs from the sandbox

2. **Drawer Visibility**
   - The drawer may be hidden by default and not transitioning correctly
   - CSS transform may not be working as expected
   - Z-index issues could be preventing the drawer from appearing

3. **Activation Handling**
   - The Redux action might not be dispatched correctly
   - Event propagation issues might prevent the drawer from opening

## Recommended Fixes

### 1. Fix the AI Button Implementation

Remove the hardcoded AI button in the Reader component and ensure the proper AIButton component is being used:

```tsx
// In Reader component's render method
// REMOVE THIS:
<div
  className="next-chapter-single-container"
  onClick={async () => {
    this.props.handleMenuMode("assistant");
    this.props.handleOriginalText(
      this.props.htmlBook.rendition.chapterText()
    );
    this.props.handleOpenMenu(true);
  }}
  style={{
    right: "70px",
    transform: "rotate(0deg)",
    fontWeight: "bold",
    fontSize: "17px",
  }}
>
  AI
</div>
```

### 2. Fix the AIButton Component

Ensure the AIButton component is properly dispatching the action:

```tsx
// In src/components/aiButton/component.tsx
handleClick = () => {
  // Make sure we're directly toggling the drawer state
  this.props.handleOpenAIDrawer(!this.props.isAIDrawerOpen);
};

// Then in render():
<button 
  className="ai-button"
  id="ai-button"
  onClick={this.handleClick}
  // ...
>
```

### 3. Update the AIPanel Container Styling

Ensure the AI panel container has proper styling for visibility:

```css
/* In src/pages/reader/index.css */
.ai-panel-container {
  width: 299px;
  height: 100vh;
  position: absolute;
  top: 0px;
  right: 0px;
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 15;
  background-color: var(--bg-color);
  box-shadow: -2px 0 10px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
}
```

### 4. Add Overlay for Mobile Experience

Add an overlay component to darken the background when the drawer is open:

```tsx
// In Reader component's render method, add this before the AIPanel:
{this.props.isAIDrawerOpen && (
  <div 
    className="ai-panel-overlay" 
    onClick={() => this.props.handleOpenAIDrawer(false)}
  />
)}
```

With corresponding CSS:

```css
/* In src/pages/reader/index.css */
.ai-panel-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  opacity: 1;
  z-index: 14;
  transition: opacity 0.3s ease;
}
```

## Testing Plan

1. Test the AI button click event
2. Verify the drawer appears and disappears correctly
3. Test on mobile devices for touch interaction
4. Check that the overlay works correctly
5. Verify all drawer options are clickable

## Additional Considerations

- Add keyboard shortcut support (e.g., Esc to close)
- Ensure proper accessibility attributes
- Add transition animations for smooth UI 