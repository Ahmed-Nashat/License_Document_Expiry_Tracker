const { request: httpsRequest } = require('node:https');

module.exports = function handler(request, response) {
  const apiUrl = process.env.RENDER_API_URL;
  if (!apiUrl) {
    response.status(500).json({ error: 'API_PROXY_NOT_CONFIGURED' });
    return;
  }

  const target = new URL(request.url, apiUrl);
  const headers = { ...request.headers, host: target.host };
  delete headers['content-length'];

  const upstream = httpsRequest(target, {
    method: request.method,
    headers,
  }, (upstreamResponse) => {
    response.writeHead(upstreamResponse.statusCode ?? 502, upstreamResponse.headers);
    upstreamResponse.pipe(response);
  });

  upstream.on('error', () => {
    if (!response.headersSent) response.status(502).json({ error: 'API_UNAVAILABLE' });
    else response.end();
  });
  request.pipe(upstream);
}
