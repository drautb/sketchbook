#!/usr/bin/env python

import json
import os

BASE = '/Users/drautb/Desktop/newont-rule-comp'
MASTER_LABELS = BASE + '/master/labels'
NEWONT_LABELS = BASE + '/newont/labels'


def get_95_from_gx(gx):
    film_number = list(filter(lambda f: "DigitalFilmNbr" in f['type'], gx['fields']))[0]['values'][0]['text']
    image_number = list(filter(lambda f: "ImageNumber" in f['type'], gx['fields']))[0]['values'][0]['text']
    return f"{film_number}_{image_number}"


def get_document(gx, doc_id):
    return list(filter(lambda d: d['id'] == doc_id, gx['documents']))[0]


def get_ner_rules(gx):
    note = get_document(gx, 'enamexPostRulesPreCorrections')['notes'][0]['text']
    return note.replace("Entity Rules Fired:\n\n", "").split('\n')


def get_relex_rules(gx):
    note = get_document(gx, 'relexPostRules')['notes'][1]['text']
    return note.replace("Relation Rules Fired:\n\n", "").split('\n')


ner_misses = {}
rel_misses = {}

for l in os.listdir(MASTER_LABELS):
    if not "_Christening" in l:
        continue

    gx = json.load(open(f"{MASTER_LABELS}/{l}/gedcomx.json", 'r'))
    new_gx = json.load(open(f"{NEWONT_LABELS}/{l}/gedcomx.json", 'r'))

    if not gx:
        continue 

    image_95 = get_95_from_gx(gx)

    data = {
        'a': image_95,
        'ner': get_ner_rules(gx),
        'rel': get_relex_rules(gx)
    }

    new_data = {
        'a': image_95,
        'ner': get_ner_rules(new_gx),
        'rel': get_relex_rules(new_gx)
    }

    # Goal is to id rules that didn't fire in the newont, that did fire before. 
    ner_diff = set(data['ner']) - set(new_data['ner'])
    rel_diff = set(data['rel']) - set(new_data['rel'])

    if len(ner_diff) > 0 or len(rel_diff) > 0:
        print(f"Difference: {image_95} - NER: {ner_diff} - REL: {rel_diff}")

        for r in ner_diff:
            if r in ner_misses:
                ner_misses[r] += 1
            else:
                ner_misses[r] = 1

        for r in rel_diff:
            if r in rel_misses:
                rel_misses[r] += 1
            else:
                rel_misses[r] = 1

print(json.dumps(ner_misses, indent=2))
print("\n")
print(json.dumps(rel_misses, indent=2))
