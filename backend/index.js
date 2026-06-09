const http = require('http');
const PORT = process.env.PORT || 5000;

const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');

  if (req.url === '/api/health') {
    res.writeHead(200);
    res.end(JSON.stringify({
      status: 'ok',
      service: 'stackforge-backend',
      timestamp: new Date().toISOString()
    }));
    return;
  }

  if (req.url.startsWith('/api/')) {
    res.writeHead(200);
    res.end(JSON.stringify({ message: 'StackForge API placeholder', path: req.url }));
    return;
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('StackForge backend placeholder running on port ' + PORT);
});