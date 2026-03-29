// Network-first Service Worker for Focus Stone
// 優先從網路抓最新版，網路失敗才用快取（離線模式）

const CACHE_NAME = 'focus-stone-v1';

// 安裝時預快取 shell 資源
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) =>
      cache.addAll([
        './',
        './index.html',
        './main.dart.js',
        './flutter_bootstrap.js',
        './manifest.json',
        './favicon.png',
      ]).catch(() => {})
    )
  );
});

// 啟動時取得控制權
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      )
    ).then(() => self.clients.claim())
  );
});

// Network-first fetch 策略
self.addEventListener('fetch', (event) => {
  // 只攔截 GET 請求
  if (event.request.method !== 'GET') return;
  // 不攔截 Firebase / 外部 API
  const url = new URL(event.request.url);
  if (!url.origin.includes(self.location.origin)) return;

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // 網路成功 → 更新快取並回傳
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      })
      .catch(() =>
        // 網路失敗 → 使用快取（離線模式）
        caches.match(event.request).then((cached) => cached || Response.error())
      )
  );
});
