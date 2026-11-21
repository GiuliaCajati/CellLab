#!/usr/bin/env python3
"""Generate the respiration guide with the installed, free local Kokoro model.

Tools/.kokoro-venv/bin/python Tools/generate_respiration_audio.py
--manifest-only exports the app's descriptions and the readable guide script.
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
OUTPUT = ROOT / 'CellLab/Resources/Audio/CellularRespiration'
CACHE = ROOT / 'Tools/audio/respiration-generation-cache.json'
SCRIPT = ROOT / 'CellLab-Respiration-Axolotl-Guide.txt'
ACRONYMS = {
    'ATP': 'ˌeɪ ˌtiː ˈpiː', 'ADP': 'ˌeɪ ˌdiː ˈpiː',
    'NAD': 'ˌɛn ˌeɪ ˈdiː', 'NADH': 'ˌɛn ˌeɪ ˌdiː ˈeɪtʃ',
    'FAD': 'ˌɛf ˌeɪ ˈdiː', 'FADH2': 'ˌɛf ˌeɪ ˌdiː ˌeɪtʃ tˈuː',
}
voice.base.opening.PRONUNCIATION_OVERRIDES.update(ACRONYMS)
# Dictionary stress, including the second syllable in pyruvate and nicotinamide.
# https://www.merriam-webster.com/dictionary/pyruvate
# https://www.merriam-webster.com/dictionary/acetyl
# https://www.merriam-webster.com/dictionary/dinucleotide
# https://dictionary.cambridge.org/us/pronunciation/english/nicotinamide
voice.base.opening.PRONUNCIATION_OVERRIDES.update({
    'pyruvate': 'paɪɹˈuːvˌeɪt', 'pyruvates': 'paɪɹˈuːvˌeɪts',
    'acetyl': 'əsˈiːtəl', 'nicotinamide': 'nˌɪkətˈiːnəmaɪd',
    'dinucleotide': 'dˌaɪnˈuːkliəˌtaɪd',
})


def records():
    folder = ROOT / 'CellLab/Features/CellularRespiration'
    sources = [folder / 'RespirationContent.swift', folder / 'RespirationNarration.swift',
               ROOT / 'Tools/export_respiration_narration.swift']
    with tempfile.TemporaryDirectory(prefix='celllab-respiration-export-') as directory:
        executable = Path(directory) / 'export'
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-respiration-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        library = json.loads(subprocess.check_output([str(executable)], text=True))
    for cue in library['recordings']:
        if not cue['text'].strip():
            raise ValueError('Empty transcript: ' + cue['id'])
        cue.update(resource='respiration.' + cue['id'] + '.wav', event=cue['id'])
    return library


def synthesis_text(text):
    # Expand chemical notation for speech; preserve the displayed words in transcripts.
    for symbol, spoken in [
        ('C₆H₁₂O₆', 'glucose'), ('NO₃⁻', 'nitrate'), ('SO₄²⁻', 'sulfate'),
        ('FADH₂', 'FADH2'), ('NAD⁺', 'NAD plus'), ('CO₂', 'carbon dioxide'),
        ('H₂O', 'water'), ('O₂', 'oxygen'), ('H⁺', 'hydrogen ions'), ('e⁻', 'electrons'),
        ('Pᵢ', 'inorganic phosphate'), ('CoA', 'coenzyme A'),
    ]:
        text = text.replace(symbol, spoken)
    text = re.sub(r'\b([2346])C\b', r'\1 carbon', text)
    text = re.sub(r'(\d+)\s*[–-]\s*(\d+)', r'\1 to \2', text)
    text = text.replace('~', 'approximately ').replace('≈', ' approximately equals ')
    text = text.replace('%', ' percent').replace('×', ' times ').replace('−', ' minus ')
    text = text.replace('→', ' becomes ').replace('+', ' plus ').replace('=', ' equals ')
    text = text.replace('&', ' and ').replace('·', ', ').replace('/', ' or ')
    text = text.replace('(', ', ').replace(')', '').replace(':', ',')
    text = re.sub(r'\b\d[\d,]*\b', lambda m: voice.sphase.number_words(int(m[0].replace(',', ''))), text)
    return ' '.join(text.split())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest-only', action='store_true')
    args = parser.parse_args()
    library = records()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    SCRIPT.write_text('Cellular respiration · Axolotl guide\n\n'
                      'Free local Kokoro · af_heart · matching the other CellLab lessons.\n'
                      'Descriptions and definitions are exported from the app, with one short introduction per step.\n'
                      'Tap the axolotl for the opening and current step; swipe to hear the next step.\n'
                      'Use the speakers for the big picture and equation. The key-player sheet has its own guide.\n'
                      'Stop, leaving the page, or backgrounding the app cancels playback. Audio is bundled for offline use.\n\n'
                      + '\n\n'.join('RECORD ' + cue['id'] + ' | ' + cue['title'] + '\n' + cue['text']
                                     for cue in library['recordings'])
                      + '\n\nRegenerate: Tools/.kokoro-venv/bin/python Tools/generate_respiration_audio.py\n',
                      encoding='utf-8')
    if not args.manifest_only:
        reference_path = ROOT / 'mitosis-opening.wav'
        reference = voice.base.read_pcm(reference_path)
        reference_hash = hashlib.sha256(reference_path.read_bytes()).hexdigest()
        cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
        model = None
        for cue in library['recordings']:
            spoken = synthesis_text(cue['text'])
            settings = {**voice.base.pronunciation_settings(spoken), 'respirationVersion': 1,
                        'speech': spoken, 'acronyms': ACRONYMS, 'reference': reference_hash}
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
    (OUTPUT / 'respiration-narration.json').write_text(json.dumps(library, ensure_ascii=False, indent=2) + '\n')
    print('Ready: %d respiration recordings.' % len(library['recordings']), flush=True)


if __name__ == '__main__':
    main()
