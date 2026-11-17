#!/usr/bin/env python3
"""Generate Central Dogma narration using only installed, local Kokoro.

Tools/.kokoro-venv/bin/python Tools/generate_central_dogma_audio.py
--manifest-only exports the app's actual spoken text without synthesis.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

import numpy as np
import onnxruntime as ort
from kokoro_onnx import Kokoro
import generate_sphase_audio as sphase

base = sphase.base
ROOT = base.ROOT
OUTPUT = ROOT / 'CellLab/Resources/Audio/CentralDogma'
CACHE = ROOT / 'Tools/audio/central-dogma-generation-cache.json'
base.opening.PRONUNCIATION_OVERRIDES.update({
    'mRNA': 'ˌɛm ˌɑːɹ ˌɛn ˈeɪ',
    'tRNA': 'ˌtiː ˌɑːɹ ˌɛn ˈeɪ',
    'rRNA': 'ˌɑːɹ ˌɑːɹ ˌɛn ˈeɪ',
    'RNAs': 'ˌɑːɹ ˌɛn ˈeɪz',
})


def records():
    folder = ROOT / 'CellLab/Features/CentralDogma'
    sources = [folder / 'CentralDogmaContent.swift', folder / 'CentralDogmaNarration.swift',
               folder / 'Game/CentralDogmaGameContent.swift', ROOT / 'Tools/export_central_dogma_narration.swift']
    with tempfile.TemporaryDirectory(prefix='celllab-central-dogma-export-') as directory:
        executable = Path(directory) / 'export'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-central-dogma-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        library = json.loads(subprocess.check_output([str(executable)], text=True))
    for entry in library['recordings']:
        if not entry['text'].strip():
            raise ValueError('Empty transcript: ' + entry['id'])
        entry.update(resource='central-dogma.' + entry['id'] + '.wav', event=entry['id'])
    return library


def synthesis_text(text):
    text = text.replace('3D', 'three dimensional').replace('3′-UAC-5′', 'three prime UAC five prime')
    # Spell individual bases, codons and anticodons; “A” must never become “uh”.
    text = re.sub(r'\b(?:[ACGTU]{3}|[ACGTU])\b',
                  lambda m: ', '.join('letter ' + letter for letter in m[0]) + ',', text)
    return sphase.synthesis_text(text)


def render(model, text, overview, normalizer=None):
    pieces = []
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    for index, sentence in enumerate(sentences):
        spoken = (normalizer or synthesis_text)(sentence)
        speech, phonetic = pronunciation_input(spoken, model.tokenizer)
        samples, rate = model.create(speech, voice=base.opening.VOICE,
                                     speed=1.03 if sentence.endswith('!') else 0.94,
                                     lang='en-us', is_phonemes=phonetic)
        samples = np.asarray(samples, dtype=np.float32)
        if rate != 24000 or not samples.size or not np.isfinite(samples).all():
            raise ValueError('Invalid local synthesis: ' + sentence)
        pieces.append(samples)
        if index < len(sentences) - 1:
            pause = 0.85 if overview and index == 0 else 0.4 if sentence.endswith('?') else 0.22
            pieces.append(np.zeros(round(pause * rate), dtype=np.float32))
    return np.concatenate(pieces)


def pronunciation_input(text, tokenizer):
    # Phonemize the surrounding text separately so possessives (mRNA’s) and
    # hyphenated terms (modified-nucleotide) retain the approved pronunciations.
    overrides = {word.lower(): value for word, value in base.opening.PRONUNCIATION_OVERRIDES.items()}
    words = '|'.join(re.escape(word) for word in sorted(overrides, key=len, reverse=True))
    pattern = re.compile(r'\b(' + words + r')\b([’\']s)?', re.I)
    matches = list(pattern.finditer(text))
    if not matches:
        return text, False
    pieces, end = [], 0
    for match in matches:
        if match.start() > end:
            pieces.append(tokenizer.phonemize(text[end:match.start()], lang='en-us'))
        phonemes = overrides[match[1].lower()] + ('z' if match[2] else '')
        if any(symbol not in tokenizer.vocab for symbol in phonemes):
            raise ValueError('Unsupported pronunciation: ' + match[0])
        pieces.append(phonemes)
        end = match.end()
    if end < len(text):
        pieces.append(tokenizer.phonemize(text[end:], lang='en-us'))
    return ' '.join(piece for piece in pieces if piece), True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest-only', action='store_true')
    args = parser.parse_args()
    library = records()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = OUTPUT / 'central-dogma-narration.json'
    if args.manifest_only:
        manifest.write_text(json.dumps(library, ensure_ascii=False, indent=2) + '\n')
        print('Exported %d Central Dogma transcripts.' % len(library['recordings']))
        return
    reference_path = ROOT / 'mitosis-opening.wav'
    reference = base.read_pcm(reference_path)
    reference_hash = hashlib.sha256(reference_path.read_bytes()).hexdigest()
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    model = None
    for entry in library['recordings']:
        settings = {**base.pronunciation_settings(synthesis_text(entry['text'])),
                    'centralDogmaVersion': 2, 'reference': reference_hash}
        fingerprint = hashlib.sha256(json.dumps({'entry': entry, 'settings': settings},
                                    sort_keys=True, ensure_ascii=False).encode()).hexdigest()
        output = OUTPUT / entry['resource']
        old = cache.get(entry['id'], {})
        if old.get('fingerprint') == fingerprint and output.exists() and old.get('sha256') == hashlib.sha256(output.read_bytes()).hexdigest():
            print('Keep ' + entry['id'], flush=True)
            continue
        if model is None:
            ort.disable_telemetry_events()
            options = ort.SessionOptions()
            options.intra_op_num_threads = 2
            session = ort.InferenceSession(str(base.opening.MODEL_DIRECTORY / base.opening.MODEL_FILES[0]),
                                           sess_options=options, providers=['CPUExecutionProvider'])
            model = Kokoro.from_session(session, str(base.opening.MODEL_DIRECTORY / base.opening.MODEL_FILES[1]))
        print('Record ' + entry['id'], flush=True)
        samples = base.match_level(render(model, entry['text'], entry['id'] == 'lesson.overview'), reference)
        base.write_pcm(output, samples)
        cache[entry['id']] = {'fingerprint': fingerprint, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                              'duration': round(samples.size / 24000, 3)}
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
    manifest.write_text(json.dumps(library, ensure_ascii=False, indent=2) + '\n')
    print('Ready: %d bundled Central Dogma recordings.' % len(library['recordings']), flush=True)


if __name__ == '__main__':
    main()
