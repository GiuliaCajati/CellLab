#!/usr/bin/env python3
"""Make the CellLab opening with free, local Kokoro speech synthesis.

After the one-time environment setup, download the free model files:
    Tools/.kokoro-venv/bin/python Tools/generate_mitosis_audio.py --download-models

Generate and play the preview (works offline):
    Tools/.kokoro-venv/bin/python Tools/generate_mitosis_audio.py --preview

No API key or paid service is used. Only --download-models accesses the network.
Kokoro runtime: https://github.com/thewh1teagle/kokoro-onnx
"""

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from urllib import error, request
import wave


PROJECT_ROOT = Path(__file__).resolve().parents[1]
NARRATION_PATH = PROJECT_ROOT / "CellLab-Mitosis-Narration.txt"
PREVIEW_PATH = PROJECT_ROOT / "mitosis-opening.wav"
MODEL_DIRECTORY = PROJECT_ROOT / "Tools" / ".kokoro-models"
MODEL_RELEASE = (
    "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1/"
)
MODEL_FILES = ("kokoro-v1.0.onnx", "voices-v1.0.bin")
VOICE = "af_heart"
# Kokoro phonemes, separate from the unchanged narration. The final /i/ keeps
# "copied" sounding like "copy-d", rather than eSpeak's short /ɪ/ ("cop-id").
PRONUNCIATION_OVERRIDES = {"copied": "kˈɑpid"}


def read_opening(narration_path: Path) -> str:
    """Select the axolotl opening, excluding headings and the alternate recording."""
    narration = narration_path.read_text(encoding="utf-8-sig")
    heading = re.search(r"(?m)^Opening · Listen[ \t]*$", narration)
    if heading is None:
        raise ValueError("The narration has no 'Opening · Listen' heading.")
    after_heading = narration[heading.end():]
    next_heading = re.search(r"(?m)^1 · Prophase\b", after_heading)
    if next_heading is None:
        raise ValueError("Cannot find the Prophase heading that ends the opening.")
    opening = after_heading[:next_heading.start()].strip()
    if not opening.startswith(
        "What do axolotl tails and the skin on your nose have in common?"
    ) or not opening.endswith("That’s mitosis!"):
        raise ValueError("The first opening does not match the requested axolotl narration.")
    return opening


def speech_segments(opening: str) -> list:
    """Keep every spoken word, adding silence and pacing changes between clips."""
    question, separator, rest = opening.partition("?")
    answer, paragraph_break, explanation = rest.strip().partition("\n\n")
    lead_in, final_question, payoff = explanation.rpartition("? ")
    if not separator or not paragraph_break or not final_question:
        raise ValueError("The opening's question/answer structure has changed.")
    if answer != "Dividing cells!" or payoff != "That’s mitosis!":
        raise ValueError("Cannot identify the opening's two playful answers.")
    explanation_sentence, sentence_break, dna_question = lead_in.partition(". ")
    if not sentence_break:
        raise ValueError("Cannot separate the explanation from the DNA question.")
    # Exact spoken text, speed, and following pause in seconds.
    return [
        (question + "?", 0.92, 1.0),
        (answer, 1.0, 0.35),
        (explanation_sentence + ".", 0.94, 0.35),
        (dna_question + "?", 0.86, 0.45),
        (payoff, 1.0, 0.0),
    ]


def pronunciation_input(spoken_text: str, tokenizer) -> tuple:
    """Override selected pronunciations without respelling the source narration."""
    overrides = [
        (word, pronunciation)
        for word, pronunciation in PRONUNCIATION_OVERRIDES.items()
        if re.search(r"\b" + re.escape(word) + r"\b", spoken_text, flags=re.IGNORECASE)
    ]
    if not overrides:
        return spoken_text, False
    phonemes = tokenizer.phonemize(spoken_text, lang="en-us")
    for word, pronunciation in overrides:
        if any(symbol not in tokenizer.vocab for symbol in pronunciation):
            raise ValueError("Unsupported pronunciation symbols for '%s'." % word)
        original = tokenizer.phonemize(word, lang="en-us")
        pattern = r"(?<!\S)" + re.escape(original) + r"(?=[\s.,!?;:]|$)"
        phonemes, replacements = re.subn(pattern, lambda _: pronunciation, phonemes)
        if not replacements:
            raise ValueError("Could not apply the pronunciation override for '%s'." % word)
    return phonemes, True


def download_models() -> None:
    """One-time public downloads; narration is never sent anywhere."""
    MODEL_DIRECTORY.mkdir(parents=True, exist_ok=True)
    for filename in MODEL_FILES:
        destination = MODEL_DIRECTORY / filename
        if destination.is_file() and destination.stat().st_size:
            print("Already downloaded: %s" % filename, flush=True)
            continue
        print("Downloading free Kokoro file: %s…" % filename, flush=True)
        temporary_path = None
        try:
            with request.urlopen(MODEL_RELEASE + filename, timeout=120) as response:
                with tempfile.NamedTemporaryFile(dir=MODEL_DIRECTORY, delete=False) as model:
                    temporary_path = Path(model.name)
                    shutil.copyfileobj(response, model)
            if not temporary_path.stat().st_size:
                raise ValueError("The download was empty: %s" % filename)
            temporary_path.replace(destination)
        finally:
            if temporary_path is not None and temporary_path.exists():
                temporary_path.unlink()


def render_opening(opening: str, output_path: Path) -> float:
    for filename in MODEL_FILES:
        if not (MODEL_DIRECTORY / filename).is_file():
            raise ValueError("Model files are missing. Run this script with --download-models first.")
    try:
        import numpy as np
        from kokoro_onnx import Kokoro
        import onnxruntime as ort
    except ImportError:
        raise ValueError(
            "Use Tools/.kokoro-venv/bin/python with the packages in "
            "Tools/requirements-mitosis-audio.txt installed."
        ) from None

    # Use the local CPU explicitly; no inference server or cloud provider.
    ort.disable_telemetry_events()
    session = ort.InferenceSession(
        str(MODEL_DIRECTORY / MODEL_FILES[0]), providers=["CPUExecutionProvider"]
    )
    kokoro = Kokoro.from_session(session, str(MODEL_DIRECTORY / MODEL_FILES[1]))
    pieces = []
    sample_rate = None
    for spoken_text, speed, pause_seconds in speech_segments(opening):
        print("  %s" % spoken_text, flush=True)
        speech_input, is_phonemes = pronunciation_input(spoken_text, kokoro.tokenizer)
        samples, clip_rate = kokoro.create(
            speech_input, voice=VOICE, speed=speed, lang="en-us", is_phonemes=is_phonemes
        )
        if sample_rate is not None and clip_rate != sample_rate:
            raise ValueError("Kokoro returned inconsistent sample rates.")
        sample_rate = clip_rate
        samples = np.asarray(samples, dtype=np.float32).reshape(-1)
        if not samples.size or not np.isfinite(samples).all():
            raise ValueError("Kokoro returned invalid audio.")
        pieces.append(samples)
        if pause_seconds:
            pieces.append(np.zeros(round(pause_seconds * sample_rate), dtype=np.float32))
    waveform = np.concatenate(pieces)
    pcm = (np.clip(waveform, -1.0, 1.0) * 32767).astype("<i2")
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(dir=output_path.parent, suffix=".wav", delete=False) as clip:
            temporary_path = Path(clip.name)
        with wave.open(str(temporary_path), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(sample_rate)
            output.writeframes(pcm.tobytes())
        temporary_path.replace(output_path)
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()
    return waveform.size / sample_rate


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    command = parser.add_mutually_exclusive_group(required=True)
    command.add_argument(
        "--download-models", action="store_true", help="Download the free model files once."
    )
    command.add_argument(
        "--preview", action="store_true", help="Generate locally, save mitosis-opening.wav, and play it."
    )
    parser.add_argument(
        "--no-play", action="store_true", help="Save the preview without starting playback."
    )
    args = parser.parse_args()
    try:
        if args.download_models:
            download_models()
            return 0
        opening = read_opening(NARRATION_PATH)
        print("Generating locally with Kokoro / %s…" % VOICE, flush=True)
        duration = render_opening(opening, PREVIEW_PATH)
        print("Saved: %s (%.1f seconds)" % (PREVIEW_PATH, duration), flush=True)
        if not args.no_play:
            print("Playing AI-generated narration. Press Ctrl-C to stop.", flush=True)
            result = subprocess.run(["/usr/bin/afplay", str(PREVIEW_PATH)], check=False)
            if result.returncode:
                raise ValueError("Playback failed; the saved WAV is still available.")
    except KeyboardInterrupt:
        print("\nStopped.", file=sys.stderr)
        return 130
    except (OSError, ValueError, error.URLError) as exc:
        print("Error: %s" % exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
