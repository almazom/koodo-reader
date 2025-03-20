// This is the service worker for Koodo Reader PWA

const CACHE_NAME = 'koodo-reader-v1';
const STATIC_CACHE = 'koodo-static-v1';
const DYNAMIC_CACHE = 'koodo-dynamic-v1';

// App shell (critical resources)
const APP_SHELL = [
  '/',
  '/index.html',
  '/favicon.png',
  '/static/css/main.css',
  '/static/js/main.js',
  '/lib/7z-wasm/7zz.umd.js',
  '/lib/libunrar/rpc.js',
  '/lib/pdfjs/pdf.mjs',
  '/lib/pdfjs/pdf.worker.mjs',
  '/lib/sqljs-wasm/sql-wasm.js'
];

// Installation - cache app shell
self.addEventListener('install', event => {
  console.log('[Service Worker] Installing Service Worker...');
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => {
        console.log('[Service Worker] Caching App Shell');
        return cache.addAll(APP_SHELL);
      })
      .then(() => self.skipWaiting())
  );
});

// Activation - clean up old caches
self.addEventListener('activate', event => {
  console.log('[Service Worker] Activating Service Worker...');
  const currentCaches = [STATIC_CACHE, DYNAMIC_CACHE];
  event.waitUntil(
    caches.keys()
      .then(cacheNames => {
        return cacheNames.filter(
          cacheName => !currentCaches.includes(cacheName)
        );
      })
      .then(cachesToDelete => {
        return Promise.all(
          cachesToDelete.map(cacheToDelete => {
            console.log('[Service Worker] Removing old cache', cacheToDelete);
            return caches.delete(cacheToDelete);
          })
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch - stale-while-revalidate strategy
self.addEventListener('fetch', event => {
  // Skip cross-origin requests
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }
  
  event.respondWith(
    caches.match(event.request)
      .then(cachedResponse => {
        if (cachedResponse) {
          // Return cached response and update cache in background
          const fetchPromise = fetch(event.request)
            .then(networkResponse => {
              // Update cache with fresh response
              if (networkResponse && networkResponse.status === 200) {
                const responseToCache = networkResponse.clone();
                caches.open(DYNAMIC_CACHE)
                  .then(cache => {
                    cache.put(event.request, responseToCache);
                  });
              }
              return networkResponse;
            })
            .catch(() => {
              // Network request failed, just use cache
              return cachedResponse;
            });
            
          // Return cached response immediately
          return cachedResponse;
        }
        
        // No cache hit, fetch from network
        return fetch(event.request)
          .then(response => {
            if (!response || response.status !== 200) {
              return response;
            }
            
            // Clone the response for caching
            const responseToCache = response.clone();
            caches.open(DYNAMIC_CACHE)
              .then(cache => {
                cache.put(event.request, responseToCache);
              });
              
            return response;
          })
          .catch(err => {
            console.log('[Service Worker] Fetch failed; returning offline page instead.', err);
            // You could return a custom offline page here
          });
      })
  );
}); 