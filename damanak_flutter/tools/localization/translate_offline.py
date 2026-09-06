"""Generate reviewable translation drafts locally; never used at app runtime.

Uses facebook/m2m100_418M (MIT). Only public UI catalog strings are processed.
Placeholder tokens are preserved by translating text segments independently.
This conservative fallback needs human review for sentence order and grammar.
"""
import json
import re
import sys
from pathlib import Path

import torch
from transformers import M2M100Config, M2M100ForConditionalGeneration, M2M100Tokenizer

root = Path(__file__).resolve().parent
catalog = json.loads((root / 'catalog.json').read_text(encoding='utf-8'))
english = json.loads((root / 'translation-cache/en.json').read_text(encoding='utf-8'))
overrides = json.loads((root / 'overrides.json').read_text(encoding='utf-8'))
for key, entry in catalog.items():
    english[key] = overrides.get(entry['text'], {}).get('en', english.get(key, ''))
model_id = 'facebook/m2m100_418M'
revision = '55c2e61bbf05dfb8d7abccdc3fae6fc8512fd636'
cache = str(root / 'model-cache')
tokenizer = M2M100Tokenizer.from_pretrained(model_id, revision=revision, cache_dir=cache, src_lang='en')
local_weights = root / 'model-cache/pytorch_model.bin'
if local_weights.exists():
    config = M2M100Config.from_pretrained(model_id, revision=revision, cache_dir=cache, local_files_only=True)
    model = M2M100ForConditionalGeneration(config)
    model.load_state_dict(torch.load(local_weights, map_location='cpu', weights_only=True))
else:
    model = M2M100ForConditionalGeneration.from_pretrained(model_id, revision=revision, cache_dir=cache)
device = 'cuda' if torch.cuda.is_available() else 'cpu'
model = model.to(device).eval()
if device == 'cuda':
    model = model.half()
torch.set_num_threads(4)
print(f'Local translation on {device}', flush=True)
protected = re.compile(r'(\{p\d+\}|\n|Damanak|App Store|Google Play|Apple|Google|OpenAI|Gemini|https?://\S+)')

for language in sys.argv[1:] or ['zh', 'hi', 'ja', 'ru']:
    output = root / f'translation-cache/{language}.json'
    results = json.loads(output.read_text(encoding='utf-8')) if output.exists() else {}
    pending = [key for key in catalog if not results.get(key)]
    for offset in range(0, len(pending), 16):
        keys = pending[offset:offset+16]
        parts_by_key = {}
        unique = {}
        for key in keys:
            source = english.get(key, '')
            if not source:
                continue
            parts = protected.split(source)
            parts_by_key[key] = parts
            for i in range(0, len(parts), 2):
                segment = parts[i].strip()
                if segment and re.search('[A-Za-z]', segment):
                    unique[segment] = None
        segments = list(unique)
        for start in range(0, len(segments), 24):
            batch = segments[start:start+24]
            encoded = tokenizer(batch, return_tensors='pt', padding=True, truncation=True, max_length=400).to(device)
            with torch.inference_mode():
                generated = model.generate(**encoded, forced_bos_token_id=tokenizer.get_lang_id(language), max_new_tokens=450, num_beams=3)
            unique.update(zip(batch, tokenizer.batch_decode(generated, skip_special_tokens=True)))
        for key, parts in parts_by_key.items():
            for i in range(0, len(parts), 2):
                segment = parts[i].strip()
                if segment in unique:
                    before = parts[i][:len(parts[i])-len(parts[i].lstrip())]
                    after = parts[i][len(parts[i].rstrip()):]
                    parts[i] = before + unique[segment] + after
            translated = ''.join(parts)
            expected = sorted(re.findall(r'\{p\d+\}', catalog[key]['text']))
            if sorted(re.findall(r'\{p\d+\}', translated)) != expected:
                raise ValueError(f'Placeholder mismatch: {language}/{key}')
            results[key] = translated
        output.write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
        print(f'{language}: {min(offset+16,len(pending))}/{len(pending)}', flush=True)
