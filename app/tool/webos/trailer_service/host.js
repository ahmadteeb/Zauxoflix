// The packaged file:// document has no HTTP origin. Serve only our own fixed
// player HTML on loopback, letting Chromium supply its normal iframe Referer.
const fs = require('fs');
const http = require('http');
const path = require('path');
const Service = require('webos-service');
const service = new Service('com.flutter.app.zauxoflix.trailer.host');
const page = fs.readFileSync(path.join(__dirname, 'player.html'));
const server = http.createServer((req, res) => {
  if (req.method !== 'GET' || req.url !== '/player') {
    res.writeHead(404);
    return res.end();
  }
  res.writeHead(200, {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-store',
    'Referrer-Policy': 'strict-origin-when-cross-origin'
  });
  res.end(page);
});
const listen = new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(0, '127.0.0.1', () => resolve(server.address().port));
});
service.register('start', message => {
  listen.then(port => message.respond({returnValue: true, port}),
    () => message.respond({returnValue: false, errorText: 'Trailer player unavailable'}));
});
