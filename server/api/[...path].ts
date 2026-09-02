import type { IncomingMessage, ServerResponse } from 'node:http';
import app from '../src/app.js';

const ready = app.ready();

export default async function handler(request: IncomingMessage, response: ServerResponse) {
  await ready;
  if (request.url?.startsWith('/api')) request.url = request.url.slice(4) || '/';
  app.server.emit('request', request, response);
}
