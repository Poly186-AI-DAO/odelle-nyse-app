const express = require('express');
const { AccessToken } = require('livekit-server-sdk');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

const livekitHost = process.env.LIVEKIT_HOST;
const livekitApiKey = process.env.LIVEKIT_API_KEY;
const livekitApiSecret = process.env.LIVEKIT_API_SECRET;

if (!livekitHost || !livekitApiKey || !livekitApiSecret) {
  console.error('Missing LiveKit environment variables. Please set LIVEKIT_HOST, LIVEKIT_API_KEY, and LIVEKIT_API_SECRET in your .env file.');
  process.exit(1);
}

app.get('/get-token', (req, res) => {
  const { roomName, participantName } = req.query;

  if (!roomName || !participantName) {
    return res.status(400).json({ error: 'roomName and participantName are required query parameters' });
  }

  const at = new AccessToken(livekitApiKey, livekitApiSecret, {
    identity: participantName,
  });

  at.addGrant({ roomJoin: true, room: roomName });

  const token = at.toJwt();

  res.json({
    serverUrl: livekitHost,
    roomName: roomName,
    participantName: participantName,
    participantToken: token,
  });
});

app.listen(port, () => {
  console.log(`LiveKit token server listening at http://localhost:${port}`);
});
