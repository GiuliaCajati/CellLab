#!/usr/bin/env python3
"""Generate Cell Structures narration with the installed, free local Kokoro voice.

Tools/.kokoro-venv/bin/python Tools/generate_cell_structures_audio.py
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
OUTPUT = ROOT / 'CellLab/Resources/Audio/CellStructures'
CACHE = ROOT / 'Tools/audio/cell-structures-generation-cache.json'


def records():
    folder = ROOT / 'CellLab/Features/CellStructures'
    sources = [folder / 'CellStructuresContent.swift', folder / 'CellStructuresNarration.swift',
               ROOT / 'Tools/export_cell_structures_narration.swift']
    with tempfile.TemporaryDirectory(prefix='celllab-structures-export-') as directory:
        executable = Path(directory) / 'export'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-structures-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        library = json.loads(subprocess.check_output([str(executable)], text=True))
    for cue in library['recordings']:
        cue.update(resource='cell-structures.' + cue['id'] + '.wav', event=cue['id'])
    return library


def synthesis_text(text):
    for notation, spoken in [('H₂O₂', 'hydrogen peroxide'), ('CO₂', 'carbon dioxide'),
                             ('H₂O', 'water'), ('O₂', 'oxygen'), ('Ca²⁺', 'calcium')]:
        text = text.replace(notation, spoken)
    text = re.sub(r'\bER\b', 'E, R,', text)
    text = re.sub(r'\bpH\b', 'P, H,', text)
    text = re.sub(r'\b(\d+)\.(\d+)\b', lambda m: m[1] + ' point ' + m[2], text)
    text = re.sub(r'\bnm\b', 'nanometers', text)
    return voice.synthesis_text(text.replace('+', ' plus '))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest-only', action='store_true')
    args = parser.parse_args()
    library = records()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = OUTPUT / 'cell-structures-narration.json'
    if not args.manifest_only:
        reference_path = ROOT / 'mitosis-opening.wav'
        reference = voice.base.read_pcm(reference_path)
        reference_hash = hashlib.sha256(reference_path.read_bytes()).hexdigest()
        cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
        model = None
        for cue in library['recordings']:
            spoken = synthesis_text(cue['text'])
            settings = {**voice.base.pronunciation_settings(spoken),
                        'structuresVersion': 1, 'speech': spoken, 'reference': reference_hash}
            if re.search(r'\bATP\b|Ca²⁺', cue['text']):
                settings['notationVersion'] = 2
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
    print('Ready: %d Cell Structures recordings.' % len(library['recordings']), flush=True)


if __name__ == '__main__':
    main()
