#!/usr/bin/env python3
"""Generate all DNA Technology narration with the installed, free local Kokoro.

Tools/.kokoro-venv/bin/python Tools/generate_dna_technology_audio.py
--manifest-only exports the live descriptions and readable script.
--check-pronunciation checks notation and phonemes without generating audio.
"""
import argparse
from concurrent.futures import ProcessPoolExecutor, as_completed
import hashlib
import json
import multiprocessing
from pathlib import Path
import re
import subprocess
import tempfile

import onnxruntime as ort
from kokoro_onnx import Kokoro
from kokoro_onnx.tokenizer import Tokenizer
import generate_central_dogma_audio as voice

ROOT = voice.ROOT
OUTPUT = ROOT / 'CellLab/Resources/Audio/DNATechnology'
CACHE = ROOT / 'Tools/audio/dna-technology-generation-cache.json'
SCRIPT = ROOT / 'CellLab-DNA-Technology-Axolotl-Guide.txt'
PRONUNCIATIONS = {
    'PCR': 'ˌpiː ˌsiː ˈɑːɹ', 'CRISPR': 'kɹˈɪspɚ', 'Cas': 'kˈæs',
    'cDNA': 'ˌsiː dˌiː ɛn ˈeɪ', 'mtDNA': 'ˌɛm ˌtiː dˌiː ɛn ˈeɪ',
    'ddNTP': 'ˌdiː ˌdiː ˌɛn ˌtiː ˈpiː', 'ddNTPs': 'ˌdiː ˌdiː ˌɛn ˌtiː ˈpiːz',
    'GMO': 'ˌdʒiː ˌɛm ˈoʊ', 'GMOs': 'ˌdʒiː ˌɛm ˈoʊz',
    'STR': 'ˌɛs ˌtiː ˈɑːɹ', 'STRs': 'ˌɛs ˌtiː ˈɑːɹz',
    'SCNT': 'ˌɛs ˌsiː ˌɛn ˈtiː', 'iPSC': 'ˌaɪ ˌpiː ˌɛs ˈsiː', 'iPSCs': 'ˌaɪ ˌpiː ˌɛs ˈsiːz',
    'IVF': 'ˌaɪ ˌviː ˈɛf', 'PGT': 'ˌpiː ˌdʒiː ˈtiː', 'PGD': 'ˌpiː ˌdʒiː ˈdiː',
    'PKU': 'ˌpiː ˌkeɪ ˈjuː', 'BRCA1': 'ˌbiː ˌɑːɹ ˌsiː ˌeɪ wˈʌn',
    'CFTR': 'ˌsiː ˌɛf ˌtiː ˈɑːɹ', 'EPO': 'ˌiː ˌpiː ˈoʊ',
    'EPSPS': 'ˌiː ˌpiː ˌɛs ˌpiː ˈɛs', 'RT': 'ˌɑːɹ ˈtiː',
    'Ti': 'ˌtiː ˈaɪ', 'Bt': 'ˌbiː ˈtiː', 'PAM': 'pˈæm', 'Taq': 'tˈæk',
    'CODIS': 'kˈoʊdɪs', 'AGAT': 'ˌeɪ ˌdʒiː ˌeɪ ˈtiː',
    # Dictionary stress and the velar nasal in Sanger's name.
    # https://www.merriam-webster.com/dictionary/Sanger
    # https://dictionary.cambridge.org/us/pronunciation/english/pluripotent
    # https://www.cancer.gov/publications/dictionaries/cancer-terms/def/erythropoietin
    # https://www.merriam-webster.com/dictionary/phenylketonuria
    'Sanger': 'sˈæŋɚ', 'pluripotent': 'plˌʊɹɪpˈoʊtənt',
    'pluripotency': 'plˌʊɹɪpˈoʊtənsi', 'erythropoietin': 'ɛɹˌɪθɹoʊpˈɔɪɛtɪn',
    'phenylketonuria': 'fˌɛnəlkˌiːtənˈʊɹiə',
    'glyphosate': 'ɡlˈaɪfəsˌeɪt', 'Bacillus': 'bəsˈɪləs',
}
voice.base.opening.PRONUNCIATION_OVERRIDES.update(PRONUNCIATIONS)
MODEL = None
REFERENCE = None


def records():
    folder = ROOT / 'CellLab/Features/DNATechnology'
    with tempfile.TemporaryDirectory(prefix='celllab-dna-technology-export-') as directory:
        executable = Path(directory) / 'export'
        # Compile the real diagrams too, so their visible notes stay in the narration.
        # Only the palette's UIKit import is unnecessary in this macOS exporter.
        palette = Path(directory) / 'Palette.swift'
        palette.write_text((folder / 'DNATechnologyArtwork.swift').read_text()
                           .split('enum DTAtlas', 1)[0].replace('import UIKit\n', ''))
        sources = [folder / 'DNATechnologyContent.swift', folder / 'DNATechnologyDiagrams.swift',
                   folder / 'DNATechnologyNarration.swift', palette, ROOT / 'Tools/export_dna_technology_narration.swift']
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/celllab-dna-technology-module-cache',
                        *map(str, sources), '-o', str(executable)], check=True)
        library = json.loads(subprocess.check_output([str(executable)], text=True))
    for cue in library['recordings']:
        if not cue['text'].strip():
            raise ValueError('Empty transcript: ' + cue['id'])
        cue.update(resource='dna-technology.' + cue['id'] + '.m4a', event=cue['id'])
    return library


def synthesis_text(text):
    text = text.replace('U.S.', 'United States').replace('Cas9', 'Cas nine')
    text = text.replace('5-enolpyruvylshikimate-3-phosphate', 'five enol pyruvyl shikimate three phosphate')
    text = re.sub(r'\bSNPs\b', 'snips', text)
    text = re.sub(r'\bSNP\b', 'snip', text)
    text = text.replace('COVID-19', 'COVID nineteen').replace('1996', 'nineteen ninety six')
    text = text.replace('2ⁿ', 'two to the power of en')
    text = re.sub(r'\b2n\b', 'two en', text)
    text = text.replace('3′', 'three prime').replace('5′', 'five prime')
    text = re.sub(r'(\d+(?:\.\d+)?)°C', r'\1 degrees Celsius', text)
    text = re.sub(r'(\d+)\s*[–−]\s*(\d+)', r'\1 to \2', text)
    text = re.sub(r'\b(\d+)\.(\d+)\b', lambda m: voice.sphase.number_words(int(m[1]))
                  + ' point ' + ' '.join(voice.sphase.number_words(int(d)) for d in m[2]), text)
    text = re.sub(r'\b\d[\d,]*\b', lambda m: voice.sphase.number_words(int(m[0].replace(',', ''))), text)
    text = text.replace('%', ' percent').replace('→', ' to ').replace('&', ' and ')
    text = text.replace('–', ' ').replace('-', ' ').replace('·', ', ')
    text = text.replace('(', ', ').replace(')', '').replace(':', ',')
    return ' '.join(text.split())


def initialize_model():
    global MODEL, REFERENCE
    ort.disable_telemetry_events()
    options = ort.SessionOptions()
    options.intra_op_num_threads = 2
    session = ort.InferenceSession(str(voice.base.opening.MODEL_DIRECTORY / voice.base.opening.MODEL_FILES[0]),
                                   sess_options=options, providers=['CPUExecutionProvider'])
    MODEL = Kokoro.from_session(session, str(voice.base.opening.MODEL_DIRECTORY / voice.base.opening.MODEL_FILES[1]))
    REFERENCE = voice.base.read_pcm(ROOT / 'mitosis-opening.wav')


def record(cue):
    print('Record ' + cue['id'], flush=True)
    text = cue['text'].replace('U.S.', 'United States')
    samples = voice.base.match_level(voice.render(MODEL, text, cue['id'] == 'lesson.overview',
                                                normalizer=synthesis_text), REFERENCE)
    path = OUTPUT / cue['resource']
    with tempfile.TemporaryDirectory(prefix='celllab-dna-technology-audio-') as directory:
        wav = Path(directory) / 'speech.wav'
        voice.base.write_pcm(wav, samples)
        subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '64000', str(wav), str(path)], check=True)
    return {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'duration': round(samples.size / 24000, 3)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest-only', action='store_true')
    parser.add_argument('--check-pronunciation', action='store_true')
    parser.add_argument('--workers', type=int, choices=[1, 2], default=2)
    args = parser.parse_args()
    library = records()
    if args.check_pronunciation:
        tokenizer = Tokenizer()
        for cue in library['recordings']:
            spoken = synthesis_text(cue['text'])
            voice.pronunciation_input(spoken, tokenizer)
            if re.search(r'[₀-₉ⁿ′°→%]', spoken):
                raise ValueError('Unexpanded notation: ' + cue['id'])
        for word in ['Sanger', 'Taq', 'pluripotent', 'electrophoresis', 'glyphosate', 'shikimate',
                     'erythropoietin', 'phenylketonuria', 'Agrobacterium', 'Bacillus thuringiensis']:
            speech, phonetic = voice.pronunciation_input(word, tokenizer)
            print(word + ': ' + (speech if phonetic else tokenizer.phonemize(speech)))
        print('Validated notation and phonemes for %d transcripts.' % len(library['recordings']))
        return
    OUTPUT.mkdir(parents=True, exist_ok=True)
    SCRIPT.write_text('DNA Technology · Axolotl guide\n\n'
                      'Free local Kokoro · af_heart · matching the other CellLab lessons.\n'
                      'The guide reads the actual topic summaries, step descriptions, biology notes, and definitions.\n'
                      'Tap the axolotl for the opening and selected step; selecting another step changes the narration.\n'
                      'The glossary has its own overview and a guide on each definition.\n'
                      'Stop, opening a sheet, leaving the page, or backgrounding the app stops speech.\n'
                      'All recordings are bundled for offline use.\n\n'
                      + '\n\n'.join('RECORD ' + cue['id'] + ' | ' + cue['title'] + '\n' + cue['text']
                                     for cue in library['recordings'])
                      + '\n\nRegenerate: Tools/.kokoro-venv/bin/python Tools/generate_dna_technology_audio.py\n', encoding='utf-8')
    if not args.manifest_only:
        reference_hash = hashlib.sha256((ROOT / 'mitosis-opening.wav').read_bytes()).hexdigest()
        cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
        pending = []
        for cue in library['recordings']:
            spoken = synthesis_text(cue['text'])
            settings = {**voice.base.pronunciation_settings(spoken), 'dnaTechnologyVersion': 1,
                        'speech': spoken, 'reference': reference_hash}
            fingerprint = hashlib.sha256(json.dumps({'entry': cue, 'settings': settings},
                                        sort_keys=True, ensure_ascii=False).encode()).hexdigest()
            path = OUTPUT / cue['resource']
            old = cache.get(cue['id'], {})
            if old.get('fingerprint') == fingerprint and path.exists() and old.get('sha256') == hashlib.sha256(path.read_bytes()).hexdigest():
                print('Keep ' + cue['id'], flush=True)
            else:
                pending.append((cue, fingerprint))
        if pending:
            with ProcessPoolExecutor(max_workers=args.workers, mp_context=multiprocessing.get_context('spawn'),
                                     initializer=initialize_model) as pool:
                jobs = {pool.submit(record, cue): (cue, fingerprint) for cue, fingerprint in pending}
                for future in as_completed(jobs):
                    cue, fingerprint = jobs[future]
                    cache[cue['id']] = {'fingerprint': fingerprint, **future.result()}
                    CACHE.parent.mkdir(parents=True, exist_ok=True)
                    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + '\n')
    (OUTPUT / 'dna-technology-narration.json').write_text(json.dumps(library, ensure_ascii=False, indent=2) + '\n')
    print('Ready: %d DNA Technology recordings.' % len(library['recordings']), flush=True)


if __name__ == '__main__':
    main()
