const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send('Hello from Container App!');
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', service: 'container-app-test' });
});

app.get('/api/info', (req, res) => {
  res.json({
    message: 'Container App API',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Container app listening on port ${port}`);
});
