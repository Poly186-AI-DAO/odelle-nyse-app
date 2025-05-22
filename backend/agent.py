from dotenv import load_dotenv
import os
from livekit.agents import AgentSession, Agent
from livekit.plugins import openai, silero
from agent_instructions import get_instructions

# Load environment variables from .env
load_dotenv()

class OdelleNyseAgent(Agent):
    def __init__(self):
        super().__init__(instructions=get_instructions())

def create_agent_session(model_choice: str):
    """
    Create an AgentSession using the selected Azure OpenAI model.
    model_choice: 'audio_preview' or 'realtime_preview'
    """
    if model_choice == 'audio_preview':
        llm = openai.LLM.with_azure(
            api_key=os.environ["AZURE_GPT_4O_AUDIO_PREVIEW_KEY"],
            base_url=os.environ["AZURE_GPT_4O_AUDIO_PREVIEW_TARGET_URL"],
            model=os.environ["AZURE_GPT_4O_AUDIO_PREVIEW"],
            api_version="2024-08-01-preview",
        )
    elif model_choice == 'realtime_preview':
        llm = openai.LLM.with_azure(
            api_key=os.environ["AZURE_GPT_4O_REALTIME_PREVIEW_KEY"],
            base_url=os.environ["AZURE_GPT_4O_REALTIME_PREVIEW_TARGET_URL"],
            model=os.environ["AZURE_GPT_4O_REALTIME_PREVIEW"],
            api_version="2024-10-01-preview",
        )
    else:
        raise ValueError(f"Unknown model_choice: {model_choice}")

    session = AgentSession(
        llm=llm,
        vad=silero.VAD.load(),
    )
    return session
