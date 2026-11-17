#!/usr/bin/env python3
"""Generate free offline S phase audio from the script and the app's real content.

Tools/.kokoro-venv/bin/python Tools/generate_sphase_audio.py
Use --manifest-only to check/export transcripts without synthesizing speech.
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
import generate_mitosis_guide_audio as base
from generate_meiosis_audio import number_words

ROOT = base.ROOT
SCRIPT = ROOT / 'CellLab-SPhase-Axolotl-Guide.txt'
OUTPUT = ROOT / 'CellLab/Resources/Audio/SPhase'
CACHE = ROOT / 'Tools/audio/sphase-generation-cache.json'
PAYOFF = 'That’s DNA replication!'
PAYOFF_PHONEMES = 'ðˈæts dˌiː ɛn ˈeɪ ɹˌɛplɪkˈeɪʃən!'
# Say the initialism smoothly as “dee-en-AY”, instead of stressing each
# space-separated letter independently. This also matches the opening reveal.
DNA_PHONEMES = 'dˌiː ɛn ˈeɪ'
base.opening.PRONUNCIATION_OVERRIDES['DNA'] = DNA_PHONEMES
# Keep the final A in RNA stressed so it cannot turn into the article “a”.
# Biology term stress follows the dictionary pronunciations:
# https://www.merriam-webster.com/dictionary/nucleotide
# https://www.merriam-webster.com/dictionary/ligase
base.opening.PRONUNCIATION_OVERRIDES.update({
    'RNA': 'ˌɑːɹ ˌɛn ˈeɪ',
    'nucleotide': 'nˈuːkliəˌtaɪd',
    'nucleotides': 'nˈuːkliəˌtaɪdz',
    'ligase': 'lˈaɪˌɡeɪs',
})


def live_content():
    folder = ROOT / 'CellLab/Features/DNAReplication'
    sources = [folder / 'DNAReplicationTheme.swift', folder / 'DNAReplicationContent.swift',
               folder / 'Game/DNACopyTypes.swift', folder / 'Game/DNACopyContent.swift',
               folder / 'Game/DNACopySession.swift', folder / 'DNAReplicationNarration.swift',
               ROOT / 'Tools/export_sphase_narration.swift']
    with tempfile.TemporaryDirectory(prefix='celllab-sphase-export-') as directory:
        executable = Path(directory) / 'export'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-sphase-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        return json.loads(subprocess.check_output([str(executable)], text=True))


def records():
    content = live_content()
    steps = {cue['id']: cue['text'] for cue in content['steps']}
    game = {cue['id']: cue for cue in content['game']}
    source = SCRIPT.read_text(encoding='utf-8').split('END OF RECORDINGS', 1)[0]
    entries = []
    for match in re.finditer(r'^RECORD ([\w.-]+) \| (.+)\n([\s\S]*?)(?=^RECORD |\Z)', source, re.M):
        cue, title, text = match.groups()
        text = text.strip()
        if cue.startswith('lesson.') and cue != 'lesson.overview':
            intro, separator, directive = text.partition('\n\n')
            slug = cue.removeprefix('lesson.')
            if not separator or directive != 'READ_PHASE_DESCRIPTION ' + slug or slug not in steps:
                raise ValueError('Missing live description for ' + cue)
            if not re.fullmatch(r'[^.!?\n]+[.!?]', intro):
                raise ValueError('Expected one introduction sentence for ' + cue)
            text = intro + '\n\n' + steps[slug]
        elif cue == 'game.origin.start':
            intro, separator, directive = text.partition('\n\n')
            if not separator or directive != 'READ_GAME_INSTRUCTION origin':
                raise ValueError('Expected the live first game instruction.')
            text = intro + '\n\n' + game.pop(cue)['text']
        entries.append({'id': cue, 'title': title, 'text': text})
    entries += content['players'] + content['terms'] + list(game.values())
    ids = {entry['id'] for entry in entries}
    if len(ids) != len(entries) or not {'lesson.' + slug for slug in steps} <= ids:
        raise ValueError('Missing or duplicate S phase cues.')
    for entry in entries:
        if not entry['text'].strip() or 'READ_' in entry['text']:
            raise ValueError('Unresolved transcript: ' + entry['id'])
        entry.update(resource='sphase.' + entry['id'] + '.wav', event=entry['id'])
    return entries


def synthesis_text(text):
    # Speech-only notation expansion; the transcript retains the on-screen words.
    text = re.sub(r'(\d+)\s*[–-]\s*(\d+)', lambda m: number_words(int(m[1])) + ' to ' + number_words(int(m[2])), text)
    text = text.replace('5′ → 3′', 'five prime to three prime')
    text = text.replace('3′', 'three prime').replace('5′', 'five prime')
    # A comma makes eSpeak use the letter name A, rather than the article “a”.
    text = text.replace('A–T', 'A, with T').replace('C–G', 'C, with G')
    # Keep DNA and RNA intact so their pronunciation overrides match every use.
    text = re.sub(r'\bATP\b', 'A, T, P', text)
    text = re.sub(r'\(([ATCG])\)', lambda m: ', letter ' + m[1] + ',', text)
    text = re.sub(r'\b\d[\d,]*\b', lambda m: number_words(int(m[0].replace(',', ''))), text)
    text = text.replace('&', ' and ').replace('→', ' to ').replace('·', ', ')
    text = text.replace('(', ', ').replace(')', '')
    text = text.replace('double-stranded', 'double stranded').replace('sugar-phosphate', 'sugar phosphate')
    return ' '.join(text.split())


def render(model, text, overview=False):
    pieces = []
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    for index, sentence in enumerate(sentences):
        spoken = synthesis_text(sentence)
        if sentence == PAYOFF:
            speech, phonetic, speed = PAYOFF_PHONEMES, True, 1.04
            if any(symbol not in model.tokenizer.vocab for symbol in speech):
                raise ValueError('Unsupported reveal phonemes.')
        else:
            speech, phonetic = base.opening.pronunciation_input(spoken, model.tokenizer)
            speed = 1.01 if sentence.endswith('!') else 0.94
        samples, rate = model.create(speech, voice=base.opening.VOICE, speed=speed,
                                     lang='en-us', is_phonemes=phonetic)
        samples = np.asarray(samples, dtype=np.float32)
        if rate != 24000 or not samples.size or not np.isfinite(samples).all():
            raise ValueError('Invalid audio for ' + sentence)
        pieces.append(samples)
        if index < len(sentences) - 1:
            pause = 0.85 if overview and index == 0 else 0.4 if sentence.endswith('?') else 0.2
            pieces.append(np.zeros(round(pause * rate), dtype=np.float32))
    return np.concatenate(pieces)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest-only', action='store_true')
    args = parser.parse_args()
    entries = records()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = OUTPUT / 'sphase-narration.json'
    if args.manifest_only:
        manifest.write_text(json.dumps({'lessonTitle': 'S phase', 'recordings': entries}, ensure_ascii=False, indent=2) + '\n')
        print('Exported %d S phase transcripts.' % len(entries))
        return
    reference = base.read_pcm(ROOT / 'mitosis-opening.wav')
    reference_hash = hashlib.sha256((ROOT / 'mitosis-opening.wav').read_bytes()).hexdigest()
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    model = None
    for entry in entries:
        settings = {**base.pronunciation_settings(synthesis_text(entry['text'])),
                    'sphaseVersion': 2 if re.search(r'A–T|C–G|\bATP\b', entry['text']) else 1,
                    'payoff': PAYOFF_PHONEMES, 'reference': reference_hash}
        fingerprint = hashlib.sha256(json.dumps({'entry': entry, 'settings': settings},
                                    sort_keys=True, ensure_ascii=False).encode()).hexdigest()
        output = OUTPUT / entry['resource']
        previous = cache.get(entry['id'], {})
        if previous.get('fingerprint') == fingerprint and output.exists() and previous.get('sha256') == hashlib.sha256(output.read_bytes()).hexdigest():
            print('Keep ' + entry['id'], flush=True)
            continue
        if model is None:
            ort.disable_telemetry_events()
            session = ort.InferenceSession(str(base.opening.MODEL_DIRECTORY / base.opening.MODEL_FILES[0]),
                                           providers=['CPUExecutionProvider'])
            model = Kokoro.from_session(session, str(base.opening.MODEL_DIRECTORY / base.opening.MODEL_FILES[1]))
        print('Record ' + entry['id'], flush=True)
        samples = base.match_level(render(model, entry['text'], overview=entry['id'] == 'lesson.overview'), reference)
        base.write_pcm(output, samples)
        cache[entry['id']] = {'fingerprint': fingerprint, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                              'duration': round(samples.size / 24000, 3)}
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
    manifest.write_text(json.dumps({'lessonTitle': 'S phase', 'recordings': entries}, ensure_ascii=False, indent=2) + '\n')
    print('Ready: %d bundled S phase recordings.' % len(entries), flush=True)


if __name__ == '__main__':
    main()
