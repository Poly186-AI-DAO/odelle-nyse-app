import os
import asyncio
import random
import string
from aiohttp import web
from livekit import api as lk_api
from agent import OdelleNyseAgent, create_agent_session
from api_config import get_model_config

# --- REST API Implementation ---
async def handle_health(request):
    return web.json_response({"status": "ok"})

async def handle_token(request):
    try:
        data = await request.json()
        identity = data.get("identity")
        room = data.get("room")
        if not identity or not room:
            return web.json_response({"error": "Missing identity or room"}, status=400)
        # Generate token using livekit-api
        token = lk_api.AccessToken() \
            .with_identity(identity) \
            .with_name(identity) \
            .with_grants(lk_api.VideoGrants(
                room_join=True,
                room=room,
            )).to_jwt()
        return web.json_response({"token": token})
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)

async def start_web_app():
    app = web.Application()
    app.router.add_get('/health', handle_health)
    app.router.add_post('/token', handle_token)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', int(os.environ.get("PORT", 8080)))
    await site.start()
    print("REST API server started on port", os.environ.get("PORT", 8080))
    # Keep running
    while True:
        await asyncio.sleep(3600)

# --- Agent Worker Entrypoint ---
def generate_room_name():
    suffix = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
    return f"nyse-room-{suffix}"

def generate_agent_identity():
    return 'agent-' + ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))

async def agent_worker(model_choice):
    session = create_agent_session(model_choice)
    room_name = generate_room_name()
    agent_identity = generate_agent_identity()
    print(f"[Agent Worker] Starting agent for model '{model_choice}' in room '{room_name}' as identity '{agent_identity}'")

    # Generate token for agent
    token = lk_api.AccessToken(
        api_key=os.environ["LIVEKIT_API_KEY"],
        api_secret=os.environ["LIVEKIT_API_SECRET"]
    ).with_identity(agent_identity) \
     .with_name(agent_identity) \
     .with_grants(lk_api.VideoGrants(
        room_join=True,
        room=room_name,
    )).to_jwt()

    # Set session properties if available
    session.agent = OdelleNyseAgent()
    session.room = room_name
    session.token = token
    await session.start(OdelleNyseAgent())

async def main():
    # Start REST API and agent workers concurrently
    model_choices = ["audio_preview", "realtime_preview"]
    tasks = [start_web_app()]
    for model_choice in model_choices:
        tasks.append(agent_worker(model_choice))
    await asyncio.gather(*tasks)

if __name__ == "__main__":
    asyncio.run(main()) 