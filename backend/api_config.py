import os
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Model configuration
AUDIO_PREVIEW_MODEL = {
    'name': os.environ.get('AZURE_GPT_4O_AUDIO_PREVIEW', 'gpt-4o-audio-preview'),
    'target_url': os.environ.get('AZURE_GPT_4O_AUDIO_PREVIEW_TARGET_URL'),
    'api_key': os.environ.get('AZURE_GPT_4O_AUDIO_PREVIEW_KEY'),
    'api_version': '2024-08-01-preview',
}

REALTIME_PREVIEW_MODEL = {
    'name': os.environ.get('AZURE_GPT_4O_REALTIME_PREVIEW', 'gpt-4o-realtime-preview'),
    'target_url': os.environ.get('AZURE_GPT_4O_REALTIME_PREVIEW_TARGET_URL'),
    'api_key': os.environ.get('AZURE_GPT_4O_REALTIME_PREVIEW_KEY'),
    'api_version': '2024-10-01-preview',
}

MODEL_MAP = {
    'audio_preview': AUDIO_PREVIEW_MODEL,
    'realtime_preview': REALTIME_PREVIEW_MODEL,
}

def get_model_config(model_choice: str):
    if model_choice not in MODEL_MAP:
        raise ValueError(f"Unknown model_choice: {model_choice}")
    return MODEL_MAP[model_choice] 