#!/usr/bin/env python3
"""Generate CellLab's home tour using the installed free local Kokoro af_heart voice.

Tools/.kokoro-venv/bin/python -X pycache_prefix=/tmp/celllab-kokoro-bytecode Tools/generate_home_audio.py
--manifest-only exports the shared app text without generating audio.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

import onnxruntime as ort
from kokoro_onnx import Kokoro
import generate_central_dogma_audio as voice

ROOT = voice.ROOT
OUTPUT = ROOT / 'CellLab/Resources/Audio/Home'
CACHE = ROOT / 'Tools/audio/home-generation-cache.json'


def synthesis_text(text):
    text = text.replace('CellLab', 'Cell Lab').replace('S Phase', 'ess phase')
    text = text.replace('PCR', 'P C R').replace('CRISPR', 'crisper')
    return voice.sphase.synthesis_text(text)


def records():
    sources = [ROOT / 'CellLab/App/CellLabHomeContent.swift', ROOT / 'Tools/export_home_narration.swift']
    with tempfile.TemporaryDirectory(prefix='celllab-home-export-') as directory:
        executable = Path(directory) / 'export'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-home-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        library = json.loads(subprocess.check_output([str(executable)], text=True))
    for cue in library['recordings']:
        cue.update(resource=cue['id'] + '.m4a', event=cue['id'])
    return library


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest-only', action='store_true')
    args = parser.parse_args()
    library = records()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (ROOT / 'CellLab-Home-Axolotl-Guide.txt').write_text(
        'CellLab · Home axolotl guide\n\nFree local Kokoro · af_heart · bundled for offline playback.\n'
        'Tap the peeking axolotl to hear the welcome on the main CellLab page. Tap a card speaker for its preview and inline details.\n'
        'Only Mitosis, Meiosis, S Phase, and Central Dogma have game badges.\n'
        'Each clip waits for your next tap. Stop, hiding details, opening a lesson, or backgrounding cancels speech.\n\n'
        + '\n\n'.join('RECORD ' + c['id'] + ' | ' + c['title'] + '\n' + c['text'] for c in library['recordings'])
        + '\n\nRegenerate: Tools/.kokoro-venv/bin/python Tools/generate_home_audio.py\n', encoding='utf-8')
    if not args.manifest_only:
        reference_path = ROOT / 'mitosis-opening.wav'
        reference = voice.base.read_pcm(reference_path)
        reference_hash = hashlib.sha256(reference_path.read_bytes()).hexdigest()
        cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
        model = None
        for cue in library['recordings']:
            spoken = synthesis_text(cue['text'])
            settings = {**voice.base.pronunciation_settings(spoken), 'homeVersion': 1,
                        'speech': spoken, 'reference': reference_hash}
            fingerprint = hashlib.sha256(json.dumps({'entry': cue, 'settings': settings},
                                        sort_keys=True, ensure_ascii=False).encode()).hexdigest()
            path = OUTPUT / cue['resource']
            old = cache.get(cue['id'], {})
            if old.get('fingerprint') == fingerprint and path.exists() and old.get('sha256') == hashlib.sha256(path.read_bytes()).hexdigest():
                print('Keep ' + cue['id'], flush=True)
                continue
            if model is None:
                ort.disable_telemetry_events()
                options = ort.SessionOptions()
                options.intra_op_num_threads = 2
                session = ort.InferenceSession(str(voice.base.opening.MODEL_DIRECTORY / voice.base.opening.MODEL_FILES[0]),
                                               sess_options=options, providers=['CPUExecutionProvider'])
                model = Kokoro.from_session(session, str(voice.base.opening.MODEL_DIRECTORY / voice.base.opening.MODEL_FILES[1]))
            print('Record ' + cue['id'], flush=True)
            samples = voice.base.match_level(voice.render(model, cue['text'], cue['id'] == 'home.overview',
                                                         normalizer=synthesis_text), reference)
            with tempfile.TemporaryDirectory(prefix='celllab-home-audio-') as directory:
                wav = Path(directory) / 'clip.wav'
                voice.base.write_pcm(wav, samples)
                subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '64000', str(wav), str(path)], check=True)
            cache[cue['id']] = {'fingerprint': fingerprint, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                                'duration': round(samples.size / 24000, 3)}
            CACHE.parent.mkdir(parents=True, exist_ok=True)
            CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
    (OUTPUT / 'home-narration.json').write_text(json.dumps(library, ensure_ascii=False, indent=2) + '\n')
    print('Ready: %d home recordings.' % len(library['recordings']), flush=True)


if __name__ == '__main__':
    main()
