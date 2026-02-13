#!/usr/bin/env python3
"""Standalone test script — validates Gemini 3 Pro Image API connectivity."""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("ERROR: GEMINI_API_KEY not found in .env")
    sys.exit(1)

client = genai.Client(api_key=api_key)
output_dir = Path("outputs")
output_dir.mkdir(exist_ok=True)

prompt = (
    "A photorealistic overhead shot of a single ripe banana resting on a clean "
    "white marble countertop. Soft, diffused natural light from a nearby window "
    "creates gentle shadows. The banana has a few small brown freckles indicating "
    "perfect ripeness. Shot with an 85mm lens, shallow depth of field, "
    "warm color temperature. Minimalist composition, editorial food photography style."
)

print("Generating test image...")
print(f"Model: gemini-3-pro-image-preview")
print(f"Prompt: {prompt}\n")

try:
    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=[prompt],
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
            image_config=types.ImageConfig(
                aspect_ratio="16:9",
                image_size="2K",
            ),
        ),
    )

    image_saved = False
    for part in response.parts:
        if part.text is not None:
            print(f"Model text: {part.text}")
        elif part.inline_data is not None:
            image = part.as_image()
            out_path = output_dir / "test-banana-v1.png"
            image.save(str(out_path))
            print(f"Image saved to: {out_path}")
            image_saved = True

    if not image_saved:
        print("WARNING: No image was returned in the response.")
        sys.exit(1)

    print("\nAPI connectivity verified. Pipeline is ready.")

except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
