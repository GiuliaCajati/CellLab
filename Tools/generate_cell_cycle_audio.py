#!/usr/bin/env python3
"""Generate Cell Life Cycle narration with the installed, free local Kokoro voice.

Tools/.kokoro-venv/bin/python Tools/generate_cell_cycle_audio.py
Use --manifest-only to export the live app descriptions without synthesizing.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

import onnxruntime as ort
from kokoro_onnx import Kokoro
import generate_central_dogma_audio as voice

ROOT = voice.ROOT
OUTPUT = ROOT / 'CellLab/Resources/Audio/CellLifeCycle'
CACHE = ROOT / 'Tools/audio/cell-cycle-generation-cache.json'


def records():
    folder = ROOT / 'CellLab/Features/CellLifeCycle'
    sources = [folder / 'CellCycleContent.swift', folder / 'CellCycleNarration.swift',
               ROOT / 'Tools/export_cell_cycle_narration.swift']
    with tempfile.TemporaryDirectory(prefix='celllab-cycle-export-') as directory:
        executable = Path(directory) / 'export'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-cycle-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        library = json.loads(subprocess.check_output([str(executable)], text=True))
    for cue in library['recordings']:
        cue.update(resource='cell-cycle.' + cue['id'] + '.wav', event=cue['id'])
    return library


def synthesis_text(text):
    # Subscript phase labels must be read as letters followed by numbers.
    for label, spoken in [('G₀', 'G zero'), ('G₁', 'G one'), ('G₂', 'G two')]:
        text = text.replace(label, spoken)
    text = re.sub(r'\bS(?= phase| checkpoints| &)', 'ess', text)
    text = re.sub(r'\bM(?= checkpoint|\))', 'em', text)
    text = re.sub(r'\bp53\b', 'p fifty three', text)
    text = re.sub(r'\bTP53\b', 'T P fifty three', text)
    text = text.replace('→', 'becomes').replace('·', ',').replace('&', 'and').replace('+', ' plus ')
    # A is an article here, rather than a DNA base label.
    return voice.sphase.synthesis_text(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest-only', action='store_true')
    args = parser.parse_args()
    library = records()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = OUTPUT / 'cell-cycle-narration.json'
    if not args.manifest_only:
        reference_path = ROOT / 'mitosis-opening.wav'
        reference = voice.base.read_pcm(reference_path)
        reference_hash = hashlib.sha256(reference_path.read_bytes()).hexdigest()
        cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
        model = None
        for cue in library['recordings']:
            spoken = synthesis_text(cue['text'])
            settings = {**voice.base.pronunciation_settings(spoken),
                        'cellCycleVersion': 1, 'speech': spoken, 'reference': reference_hash}
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
            samples = voice.base.match_level(voice.render(model, cue['text'], cue['id'] == 'lesson.overview',
                                                         normalizer=synthesis_text), reference)
            voice.base.write_pcm(path, samples)
            cache[cue['id']] = {'fingerprint': fingerprint, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                                'duration': round(samples.size / 24000, 3)}
            CACHE.parent.mkdir(parents=True, exist_ok=True)
            CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
    manifest.write_text(json.dumps(library, ensure_ascii=False, indent=2) + '\n')
    print('Ready: %d Cell Life Cycle recordings.' % len(library['recordings']), flush=True)


if __name__ == '__main__':
    main()
