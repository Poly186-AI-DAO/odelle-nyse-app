from dotenv import load_dotenv
import os
from livekit import agents
from livekit.agents import AgentSession, Agent, RoomInputOptions
from livekit.plugins import openai, azure, silero
from backend.agent_instructions import get_instructions

# Load environment variables from .env
load_dotenv()

class OdelleNyseAgent(Agent):
    def __init__(self):
        super().__init__(instructions=get_instructions())

async def entrypoint(ctx: agents.JobContext):
    session = AgentSession(
        stt=azure.STT(
            key=os.environ["AZURE_SPEECH_KEY"],
            region=os.environ["AZURE_SPEECH_REGION"]
        ),
        llm=openai.LLM(
            model=os.environ.get("AZURE_GPT_4O", "gpt-4o"),  # fallback to 'gpt-4o' if not set
            api_key=os.environ["AZURE_OPENAI_API_KEY"],
            base_url=os.environ["AZURE_OPENAI_API_BASE"]
        ),
        tts=azure.TTS(
            key=os.environ["AZURE_SPEECH_KEY"],
            region=os.environ["AZURE_SPEECH_REGION"]
        ),
        vad=silero.VAD.load(),
    )
    await session.start(
        room=ctx.room,
        agent=OdelleNyseAgent(),
        room_input_options=RoomInputOptions()
    )
    await ctx.connect()

if __name__ == "__main__":
    agents.cli.run_app(agents.WorkerOptions(entrypoint_fnc=entrypoint))
