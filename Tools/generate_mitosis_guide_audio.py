#!/usr/bin/env python3
"""Generate missing/changed Mitosis guide clips with free, offline Kokoro.

Tools/.kokoro-venv/bin/python Tools/generate_mitosis_guide_audio.py
The approved mitosis-opening.wav is read, never regenerated or overwritten.
The RECORD script and live phase/key-player descriptions supply the transcripts.
"""
import hashlib
import json
from pathlib import Path
import re
import wave

import numpy as np
import onnxruntime as ort
from kokoro_onnx import Kokoro

import generate_mitosis_audio as opening

ROOT = opening.PROJECT_ROOT
OUTPUT = ROOT / 'CellLab/Resources/Audio/Mitosis'
CACHE_PATH = ROOT / 'Tools/audio/mitosis-generation-cache.json'
SCRIPT = ROOT / 'CellLab-Mitosis-Axolotl-Guide.txt'
PLAYER_SOURCE = ROOT / 'CellLab/Features/Mitosis/MitosisKeyPlayersView.swift'
PHASE_SOURCE = ROOT / 'CellLab/Features/Mitosis/Mitosis.swift'
# Keep synthesis pronunciation separate from visible spelling. Stress follows:
# https://www.merriam-webster.com/medical/prometaphase
# https://www.merriam-webster.com/dictionary/kinetochore
opening.PRONUNCIATION_OVERRIDES.update({
    'prophase': 'pɹˈoʊfeɪz',
    # Keep the full "forty" syllables; eSpeak otherwise joins the hyphenated words.
    'forty-six': 'fˌɔːɹti sˈɪks',
    'prometaphase': 'pɹoʊmˈɛtəˌfeɪz',
    'chromatid': 'kɹˈoʊmətɪd',
    'chromatids': 'kɹˈoʊmətɪdz',
    'kinetochore': 'kənˈɛtəˌkɔɹ',
    'kinetochores': 'kənˈɛtəˌkɔɹz',
})
SETTINGS = {'voice': opening.VOICE, 'speed': 0.94, 'version': 1,
            'pronunciations': opening.PRONUNCIATION_OVERRIDES}
# Migrate the original cache, which included every pronunciation in every cue's
# fingerprint. New fingerprints depend only on words actually spoken in a cue.
LEGACY_SETTINGS = {**SETTINGS, 'pronunciations': {
    word: pronunciation for word, pronunciation in opening.PRONUNCIATION_OVERRIDES.items()
    if word not in {'prophase', 'forty-six'}
}}


def pronunciation_settings(text):
    return {**SETTINGS, 'pronunciations': {
        word: pronunciation for word, pronunciation in opening.PRONUNCIATION_OVERRIDES.items()
        if re.search(r'\b' + re.escape(word) + r'\b', text, re.IGNORECASE)
    }}


def cue_fingerprint(entry, hook_hash, settings):
    return hashlib.sha256(json.dumps({'entry': entry, 'settings': settings,
        'hook': hook_hash}, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def phase_descriptions():
    """Read the same literal explanation points the phase cards display.

    Fail on an unsupported Swift expression rather than silently omitting words.
    """
    source = PHASE_SOURCE.read_text(encoding='utf-8')
    block = re.search(r'var explanationPoints: \[String\] \{(.*?)\n    var explanation: String',
                      source, re.S)
    if block is None:
        raise ValueError('Could not find the live phase explanation points.')
    descriptions = {}
    string_literal = r'"(?:[^"\\]|\\.)*"'
    for phase, body in re.findall(r'case \.(\w+):\s*\[([^\]]*)\]', block.group(1)):
        literals = re.findall(string_literal, body)
        remainder = re.sub(string_literal, '', body)
        if not literals or remainder.strip(' \t\r\n,') or phase in descriptions:
            raise ValueError('Expected literal description points for ' + phase)
        descriptions[phase] = ' '.join(json.loads(value) for value in literals)
    expected = {'prophase', 'prometaphase', 'metaphase', 'anaphase', 'telophase', 'cytokinesis'}
    if set(descriptions) != expected:
        raise ValueError('Expected all six live phase descriptions.')
    return descriptions


def records():
    text = SCRIPT.read_text(encoding='utf-8').split('END OF RECORDINGS', 1)[0]
    descriptions = phase_descriptions()
    entries = []
    for match in re.finditer(r'^RECORD ([\w.-]+) \| (.+)\n([\s\S]*?)(?=^RECORD |\Z)', text, re.M):
        cue, title, spoken = match.groups()
        spoken = spoken.strip()
        if cue in {'lesson.' + phase for phase in descriptions if phase != 'cytokinesis'}:
            phase = cue.removeprefix('lesson.')
            marker = 'READ_PHASE_DESCRIPTION ' + phase
            intro, separator, directive = spoken.partition('\n\n')
            if not separator or directive != marker or not re.fullmatch(r'[^.!?\n]+[.!?]', intro):
                raise ValueError('Expected one intro sentence and ' + marker + ' for ' + cue)
            spoken = intro + '\n\n' + descriptions[phase]
        if 'READ_PHASE_DESCRIPTION' in spoken:
            raise ValueError('Unresolved phase description directive in ' + cue)
        entries.append({'id': cue, 'title': title.strip(), 'text': spoken.strip(),
                        'resource': cue + '.wav', 'event': cue})
    source = PLAYER_SOURCE.read_text(encoding='utf-8')
    players = re.findall(r'name: "([^"\n]+)",\s*definition: "((?:[^"\\]|\\.)*)"', source)
    if len(players) != 6:
        raise ValueError('Expected the six live Mitosis key-player definitions.')
    for name, definition in players:
        definition = json.loads('"' + definition + '"')
        cue = 'player.' + re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')
        entries.append({'id': cue, 'title': name, 'text': name + '. ' + definition,
                        'resource': cue + '.wav', 'event': cue})
    if len(entries) != 32 or len({r['id'] for r in entries}) != len(entries):
        raise ValueError('Expected 26 RECORD entries and six key-player clips, with unique IDs.')
    return entries


def read_pcm(path):
    with wave.open(str(path), 'rb') as clip:
        if (clip.getnchannels(), clip.getsampwidth(), clip.getframerate()) != (1, 2, 24000):
            raise ValueError('Expected 24 kHz mono PCM: ' + str(path))
        return np.frombuffer(clip.readframes(clip.getnframes()), dtype='<i2').astype(np.float32) / 32768


def write_pcm(path, samples):
    pcm = (np.clip(samples, -1, 1) * 32767).astype('<i2')
    with wave.open(str(path), 'wb') as clip:
        clip.setnchannels(1)
        clip.setsampwidth(2)
        clip.setframerate(24000)
        clip.writeframes(pcm.tobytes())


def match_level(samples, target):
    # Compare speech-bearing samples, excluding breaths and inserted pauses.
    def rms(values):
        voiced = values[np.abs(values) > 0.015]
        return np.sqrt(np.mean(voiced ** 2)) if voiced.size else 0.1
    gain = np.clip(rms(target) / max(rms(samples), 0.001), 0.5, 2)
    peak = float(np.max(np.abs(samples)))
    gain = min(gain, 0.96 / peak) if peak else gain
    return samples * gain


def render(model, text):
    pieces = []
    # Sentences retain their words and punctuation; no headings are synthesized.
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    for index, sentence in enumerate(sentences):
        speech, phonetic = opening.pronunciation_input(sentence, model.tokenizer)
        samples, rate = model.create(speech, voice=opening.VOICE, speed=0.94,
                                     lang='en-us', is_phonemes=phonetic)
        assert rate == 24000
        samples = np.asarray(samples, dtype=np.float32)
        if not samples.size or not np.isfinite(samples).all():
            raise ValueError('Invalid synthesis for: ' + sentence)
        pieces.append(samples)
        if index < len(sentences) - 1:
            pieces.append(np.zeros(round((0.35 if sentence.endswith('?') else 0.18) * rate), dtype=np.float32))
    return np.concatenate(pieces)


def main():
    entries = records()
    hook_path = ROOT / 'mitosis-opening.wav'
    hook_bytes = hook_path.read_bytes()
    hook = read_pcm(hook_path)
    hook_hash = hashlib.sha256(hook_bytes).hexdigest()
    known_opening = opening.read_opening(opening.NARRATION_PATH)
    overview = entries[0]
    if overview['id'] != 'lesson.overview' or not overview['text'].startswith(known_opening + '\n\n'):
        raise ValueError('Overview must begin with the exact approved opening.')
    OUTPUT.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    cache = json.loads(CACHE_PATH.read_text()) if CACHE_PATH.exists() else {}
    model = None
    generated = 0
    for entry in entries:
        fingerprint = cue_fingerprint(entry, hook_hash, pronunciation_settings(entry['text']))
        allowed_fingerprints = {fingerprint}
        if not re.search(r'\b(?:prophase|forty-six)\b', entry['text'], re.IGNORECASE):
            allowed_fingerprints.add(cue_fingerprint(entry, hook_hash, LEGACY_SETTINGS))
        output = OUTPUT / entry['resource']
        old = cache.get(entry['id'], {})
        if old.get('fingerprint') in allowed_fingerprints and output.exists() and old.get('sha256') == hashlib.sha256(output.read_bytes()).hexdigest():
            cache[entry['id']]['fingerprint'] = fingerprint
            print('Keep ' + entry['id'], flush=True)
            continue
        if model is None:
            ort.disable_telemetry_events()
            session = ort.InferenceSession(str(opening.MODEL_DIRECTORY / opening.MODEL_FILES[0]),
                                           providers=['CPUExecutionProvider'])
            model = Kokoro.from_session(session, str(opening.MODEL_DIRECTORY / opening.MODEL_FILES[1]))
        print('Record ' + entry['id'], flush=True)
        if entry['id'] == 'lesson.overview':
            tail_text = entry['text'][len(known_opening):].strip()
            tail = match_level(render(model, tail_text), hook)
            write_pcm(output, np.concatenate([hook, np.zeros(8400, dtype=np.float32), tail]))
            # Preserve the original hook's PCM bits exactly, including its timing.
            with wave.open(str(hook_path), 'rb') as old_clip:
                original_frames = old_clip.readframes(old_clip.getnframes())
            with wave.open(str(output), 'rb') as new_clip:
                total_frames = new_clip.readframes(new_clip.getnframes())
            with wave.open(str(output), 'wb') as final_clip:
                final_clip.setnchannels(1); final_clip.setsampwidth(2); final_clip.setframerate(24000)
                final_clip.writeframes(original_frames + total_frames[len(original_frames):])
        else:
            write_pcm(output, match_level(render(model, entry['text']), hook))
        samples = read_pcm(output)
        cache[entry['id']] = {'fingerprint': fingerprint, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                              'duration': round(samples.size / 24000, 3)}
        CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
        generated += 1
    CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
    (OUTPUT / 'mitosis-narration.json').write_text(json.dumps(
        {'lessonTitle': 'Mitosis', 'recordings': entries}, ensure_ascii=False, indent=2) + '\n')
    assert hashlib.sha256(hook_path.read_bytes()).hexdigest() == hook_hash
    print('Ready: %d cues (%d generated); approved hook unchanged.\n%s' % (len(entries), generated, OUTPUT))


if __name__ == '__main__':
    main()
