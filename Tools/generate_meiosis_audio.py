#!/usr/bin/env python3
"""Bundle free, offline Meiosis narration using the existing local Kokoro setup.

Tools/.kokoro-venv/bin/python Tools/generate_meiosis_audio.py

The phase cards, key players, and live game model supply their own descriptions.
Only missing or changed cues are synthesized. Mitosis recordings are never edited.
"""
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

ROOT = base.ROOT
SOURCE = ROOT / 'CellLab/Features/Meiosis/MeiosisKeyPlayersView.swift'
SCRIPT = ROOT / 'CellLab-Meiosis-Axolotl-Guide.txt'
OUTPUT = ROOT / 'CellLab/Resources/Audio/Meiosis'
CACHE_PATH = ROOT / 'Tools/audio/meiosis-generation-cache.json'
PHASES = ['prophaseI', 'metaphaseI', 'anaphaseI', 'telophaseI',
          'prophaseII', 'metaphaseII', 'anaphaseII', 'telophaseII']
PAYOFF = 'That’s meiosis!'
PAYOFF_PHONEMES = 'ðˈæts maɪˈoʊsɪs!'
base.opening.PRONUNCIATION_OVERRIDES.update({
    'meiosis': 'maɪˈoʊsɪs',
    'meioses': 'maɪˈoʊsiːz',
    'synapsis': 'sɪnˈæpsɪs',
    'chiasma': 'kaɪˈæzmə',
    'chiasmata': 'kaɪˈæzmətə',
    'oogenesis': 'ˌoʊədʒˈɛnəsɪs',
})


def live_descriptions():
    source = SOURCE.read_text(encoding='utf-8')
    block = source.split('enum MeiPhase:', 1)[1].split('var explanation: String', 1)[1]
    phases = {}
    for phase, text in re.findall(r'case \.(\w+):\s*return """(.*?)"""', block, re.S):
        phases[phase] = ' '.join(line.strip().removeprefix('• ') for line in text.strip().splitlines())
    if set(phases) != set(PHASES):
        raise ValueError('Expected the eight literal live Meiosis phase descriptions.')
    players = re.findall(r'\.init\(name: "([^"\n]+)",\s*definition: "((?:[^"\\]|\\.)*)"', source)
    if len(players) != 17:
        raise ValueError('Expected the seventeen live Meiosis key-player definitions.')
    players = [(name, json.loads('"' + definition + '"')) for name, definition in players]
    # These three illustrated pages contain literal bullet lists and notes.
    cards = source.split('private struct MeiPlayerCard:', 1)[1].split('@ViewBuilder private var illustration:', 1)[0]
    crew = {}
    for key, title in [('crossing', 'Crossing over'), ('assortment', 'Independent assortment'),
                       ('fertilization', 'Random fertilization')]:
        match = re.search(r'case \.' + key + r':(.*?)(?=\n\s*case \.)', cards, re.S)
        if match is None:
            raise ValueError('Could not read the illustrated ' + title + ' description.')
        literals = re.findall(r'Mei(?:BulletList|Note)\(text: ("(?:[^"\\]|\\.)*")', match.group(1))
        if len(literals) != 3:
            raise ValueError('Expected two descriptions and one note for ' + title)
        crew[key] = (title, '\n\n'.join(json.loads(value) for value in literals))
    return phases, players, crew


def game_records():
    sources = [ROOT / 'CellLab/Features/Meiosis/Game/MeiosisSession.swift',
               ROOT / 'CellLab/Features/Meiosis/MeiosisNarrationEvents.swift',
               ROOT / 'Tools/export_meiosis_narration.swift']
    # Compile outside the app from its real model; no mirrored game prose.
    with tempfile.TemporaryDirectory(prefix='celllab-meiosis-') as directory:
        executable = Path(directory) / 'export'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-meiosis-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        return json.loads(subprocess.check_output([str(executable)], text=True))


def records():
    phases, players, crew = live_descriptions()
    text = SCRIPT.read_text(encoding='utf-8').split('END OF RECORDINGS', 1)[0]
    entries = []

    def add(cue, title, spoken):
        if not spoken.strip() or 'READ_PHASE_DESCRIPTION' in spoken:
            raise ValueError('Unresolved or empty narration: ' + cue)
        entries.append({'id': cue, 'title': title, 'text': spoken.strip(),
                        'resource': 'meiosis.' + cue + '.wav', 'event': cue})

    for match in re.finditer(r'^RECORD ([\w.-]+) \| (.+)\n([\s\S]*?)(?=^RECORD |\Z)', text, re.M):
        cue, title, spoken = match.groups()
        spoken = spoken.strip()
        if cue.startswith('lesson.') and cue != 'lesson.overview':
            intro, separator, directive = spoken.partition('\n\n')
            if not separator or not re.fullmatch(r'[^.!?\n]+[.!?]', intro):
                raise ValueError('Expected one introduction sentence for ' + cue)
            phase = directive.removeprefix('READ_PHASE_DESCRIPTION ')
            if directive != 'READ_PHASE_DESCRIPTION ' + phase or phase not in phases:
                raise ValueError('Expected a live phase description for ' + cue)
            expected_id = 'lesson.' + re.sub(r'(II|I)$', lambda m: '-' + m[1].lower(), phase)
            if cue != expected_id:
                raise ValueError('Phase directive does not match its cue: ' + cue)
            spoken = intro + '\n\n' + phases[phase]
        add(cue, title, spoken)
    for index, (name, definition) in enumerate(players):
        add('player.term-' + str(index), name, name + '. ' + definition)
    for key, (title, explanation) in crew.items():
        add('player.' + key, title, title + '. ' + explanation)
    for cue in game_records():
        add(cue['id'], cue['title'], cue['text'])
    if len(entries) != 64 or len({entry['id'] for entry in entries}) != 64:
        raise ValueError('Expected 64 unique Meiosis cues.')
    return entries


def number_words(number):
    small = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
             'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
             'seventeen', 'eighteen', 'nineteen']
    tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety']
    if number < 20:
        return small[number]
    if number < 100:
        return tens[number // 10] + ('-' + small[number % 10] if number % 10 else '')
    for value, name in [(10**12, 'trillion'), (10**9, 'billion'), (10**6, 'million'),
                        (1000, 'thousand'), (100, 'hundred')]:
        if number >= value:
            return number_words(number // value) + ' ' + name + (' ' + number_words(number % value) if number % value else '')
    raise ValueError('Unsupported number: ' + str(number))


def synthesis_text(text):
    """Say displayed notation naturally, without changing the visible transcript."""
    text = re.sub(r'\b(meiosis|prophase|metaphase|anaphase|telophase) (II|I)\b',
                  lambda m: m[1] + (' two' if m[2] == 'II' else ' one'), text, flags=re.I)
    text = re.sub(r'\bI and II\b', 'one and two', text)
    text = re.sub(r'\bII\b', 'two', text)
    for displayed, spoken in [('2²³', 'two to the power of twenty-three'), ('2²', 'two squared'),
                              ('2ⁿ', 'two to the power of n'), ('2n', 'two n'),
                              ('vs.', 'versus'), ('→', ' becomes '), ('=', ' equals '),
                              ('×', ' times '), ('+', ' plus '), ('·', ', '), ('&', ' and '),
                              ('A/B', 'A and B'), ('C/D', 'C and D')]:
        text = text.replace(displayed, spoken)
    # Parentheses and compound hyphens otherwise join phonemes to nearby words,
    # preventing the shared pronunciation dictionary from matching whole words.
    text = text.replace('(', ', ').replace(')', '')
    text = text.replace('single-chromatid', 'single chromatid').replace('non-sister', 'non sister')
    text = re.sub(r'\bXX\b', 'X X', text)
    text = re.sub(r'\bXY\b', 'X Y', text)
    text = re.sub(r'\b\d[\d,]*\b', lambda m: number_words(int(m[0].replace(',', ''))), text)
    return ' '.join(text.split())


def render(model, text, overview=False):
    pieces = []
    sentences = re.split(r'(?<=[!?])\s+|(?<!vs\.)(?<=\.)\s+', text.strip())
    for index, sentence in enumerate(sentences):
        spoken = synthesis_text(sentence)
        if spoken == PAYOFF:
            speech, phonetic, speed = PAYOFF_PHONEMES, True, 1.04
            if any(symbol not in model.tokenizer.vocab for symbol in speech):
                raise ValueError('Unsupported closing-reveal phonemes.')
        else:
            speech, phonetic = base.opening.pronunciation_input(spoken, model.tokenizer)
            speed = 1.02 if spoken == 'A chromosome shuffle!' else 0.94
        samples, rate = model.create(speech, voice=base.opening.VOICE, speed=speed,
                                     lang='en-us', is_phonemes=phonetic)
        samples = np.asarray(samples, dtype=np.float32)
        if rate != 24000 or not samples.size or not np.isfinite(samples).all():
            raise ValueError('Invalid synthesis: ' + sentence)
        if spoken == PAYOFF:
            samples *= min(1.10, 0.96 / max(float(np.max(np.abs(samples))), 0.001))
        pieces.append(samples)
        if index < len(sentences) - 1:
            pause = 0.85 if overview and index == 0 else 0.4 if sentence.endswith('?') else 0.18
            pieces.append(np.zeros(round(pause * rate), dtype=np.float32))
    return np.concatenate(pieces)


def main():
    entries = records()
    reference_path = ROOT / 'mitosis-opening.wav'
    reference_bytes = reference_path.read_bytes()
    reference = base.read_pcm(reference_path)
    reference_hash = hashlib.sha256(reference_bytes).hexdigest()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    cache = json.loads(CACHE_PATH.read_text()) if CACHE_PATH.exists() else {}
    model = None
    generated = 0
    for entry in entries:
        settings = base.pronunciation_settings(synthesis_text(entry['text']))
        settings = {**settings, 'meiosisVersion': 1, 'payoff': PAYOFF_PHONEMES,
                    'reference': reference_hash}
        fingerprint = hashlib.sha256(json.dumps({'entry': entry, 'settings': settings},
                                    sort_keys=True, ensure_ascii=False).encode()).hexdigest()
        output = OUTPUT / entry['resource']
        old = cache.get(entry['id'], {})
        if old.get('fingerprint') == fingerprint and output.exists() and old.get('sha256') == hashlib.sha256(output.read_bytes()).hexdigest():
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
        CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
        generated += 1
    (OUTPUT / 'meiosis-narration.json').write_text(json.dumps(
        {'lessonTitle': 'Meiosis', 'recordings': entries}, ensure_ascii=False, indent=2) + '\n')
    assert reference_path.read_bytes() == reference_bytes
    print('Ready: %d Meiosis cues (%d generated); Mitosis opening unchanged.' % (len(entries), generated))


if __name__ == '__main__':
    main()
