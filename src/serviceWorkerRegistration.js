// This file handles registration and lifecycle management of the service worker

// Determine if we're in production mode
const isProduction = process.env.NODE_ENV === 'production';

export function register() {
  if ('serviceWorker' in navigator) {
    // Only register service worker in production
    if (isProduction) {
      window.addEventListener('load', () => {
        const swUrl = `${process.env.PUBLIC_URL}/service-worker.js`;
        
        registerValidSW(swUrl);
      });
    } else {
      console.log('Service worker registration skipped in development mode');
    }
  } else {
    console.log('Service workers are not supported by this browser');
  }
}

function registerValidSW(swUrl) {
  navigator.serviceWorker
    .register(swUrl)
    .then(registration => {
      console.log('Service worker registered successfully with scope:', registration.scope);
      
      registration.onupdatefound = () => {
        const installingWorker = registration.installing;
        if (installingWorker == null) {
          return;
        }
        
        installingWorker.onstatechange = () => {
          if (installingWorker.state === 'installed') {
            if (navigator.serviceWorker.controller) {
              // At this point, the updated precached content has been fetched,
              // but the previous service worker will still serve the older
              // content until all client tabs are closed.
              console.log('New content is available; please refresh the page');
              
              // Optional: Notify the user that new content is available
              if (window.confirm('New version available! Reload to update?')) {
                window.location.reload();
              }
            } else {
              // At this point, everything has been precached.
              console.log('Content is cached for offline use');
            }
          }
        };
      };
    })
    .catch(error => {
      console.error('Error during service worker registration:', error);
    });
}

export function unregister() {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.ready
      .then(registration => {
        registration.unregister();
      })
      .catch(error => {
        console.error(error.message);
      });
  }
} 