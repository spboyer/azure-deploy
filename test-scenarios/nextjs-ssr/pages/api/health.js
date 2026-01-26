export default function handler(req, res) {
  res.status(200).json({ status: 'OK', app: 'nextjs-ssr' });
}
