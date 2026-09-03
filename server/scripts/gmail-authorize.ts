import { createServer } from 'node:http';
import { readFile, writeFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { resolve } from 'node:path';

const clientPath = process.argv[2];
if (!clientPath) throw new Error('Pass the downloaded Google OAuth JSON path as the first argument.');

const clientFile = JSON.parse(await readFile(resolve(clientPath), 'utf8')) as {
  installed?: { client_id: string; client_secret: string };
  web?: { client_id: string; client_secret: string };
};
const client = clientFile.installed ?? clientFile.web;
if (!client) throw new Error('OAuth JSON does not contain an installed or web client.');

const redirectUri = 'http://127.0.0.1:53682/oauth2callback';
const authorizationUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
authorizationUrl.search = new URLSearchParams({
  client_id: client.client_id,
  redirect_uri: redirectUri,
  response_type: 'code',
  access_type: 'offline',
  prompt: 'consent',
  include_granted_scopes: 'true',
  scope: [
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/calendar.events',
  ].join(' '),
}).toString();

const server = createServer(async (request, response) => {
  const callback = new URL(request.url ?? '/', redirectUri);
  const code = callback.searchParams.get('code');
  const error = callback.searchParams.get('error');
  if (error || !code) {
    response.end('Authorization was cancelled. You can close this window.');
    server.close();
    process.exitCode = 1;
    return;
  }

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: client.client_id,
      client_secret: client.client_secret,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    }),
  });
  if (!tokenResponse.ok) throw new Error(`Google token exchange failed: ${tokenResponse.status}`);
  const token = await tokenResponse.json() as { refresh_token?: string; access_token?: string; expires_in?: number };
  if (!token.refresh_token) throw new Error('Google did not return a refresh token. Run again with consent approval.');
  await writeFile(resolve('.gmail-token.json'), JSON.stringify({ clientId: client.client_id, clientSecret: client.client_secret, refreshToken: token.refresh_token }, null, 2), { mode: 0o600 });
  response.end('Authorization complete. You can close this window.');
  server.close();
  console.log('Google authorization complete. Token saved locally in server/.gmail-token.json.');
});

server.listen(53682, '127.0.0.1', () => {
  console.log('Opening Google authorization in your browser...');
  execFile('rundll32.exe', ['url.dll,FileProtocolHandler', authorizationUrl.toString()]);
});
