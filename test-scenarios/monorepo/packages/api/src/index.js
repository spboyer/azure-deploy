const express = require('express');
const app = express();
const port = process.env.PORT || 3001;

app.get('/health', (req, res) => {
  res.json({ status: 'OK', service: 'api' });
});

app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from API', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`API server running on port ${port}`);
});
