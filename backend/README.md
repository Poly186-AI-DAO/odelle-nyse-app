# LiveKit Token Server

This is a simple Node.js Express server that generates access tokens for LiveKit.

## Setup

1.  **Install dependencies:**
    ```bash
    npm install
    ```

2.  **Create a `.env` file** in the `backend` directory with the following environment variables:
    ```
    LIVEKIT_HOST=your_livekit_host
    LIVEKIT_API_KEY=your_livekit_api_key
    LIVEKIT_API_SECRET=your_livekit_api_secret
    PORT=3000 # Optional, defaults to 3000
    ```
    Replace `your_livekit_host`, `your_livekit_api_key`, and `your_livekit_api_secret` with your actual LiveKit credentials. You can find these in your LiveKit Cloud dashboard or server configuration.

## Running the server

```bash
node index.js
```

The server will start listening on the port specified in your `.env` file (or 3000 by default).

## API Endpoint

### `GET /get-token`

Generates a LiveKit access token.

**Query Parameters:**

*   `roomName` (string, required): The name of the room to join.
*   `participantName` (string, required): The name of the participant.

**Example Request:**

```
GET http://localhost:3000/get-token?roomName=my-room&participantName=test-user
```

**Example Response:**

```json
{
  "serverUrl": "your_livekit_host",
  "roomName": "my-room",
  "participantName": "test-user",
  "participantToken": "generated_jwt_token"
}
```
