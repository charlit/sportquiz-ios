#!/usr/bin/python3
"""Écrit les données du quiz dans Game/*.js sans le contenu retiré de l'app (App Review 5.2.1) :
ni Coupe du monde, FIFA, CAN, ni sélections nationales, même en mauvaise réponse. Le site garde tout.
FIFA_RX / FIFA_CS doivent rester identiques à ceux d'index.html (cleanApp refiltre aussi au lancement)."""
import glob, json, os, re, sys

src, dst = sys.argv[1], sys.argv[2]
FIFA_RX = re.compile(r"coupe du monde|mondia(l|ux)|mundial|champion(ne)?s? du monde|conf[ée]d[ée]rations?|fifa|coupe d.afrique|s[ée]lection|internationa|[ée]quipe (de france|nationale)|\beuro\b|championnat d.europe des nations|ligue des nations|copa am[ée]rica|jeux (olympiques|d.|de )|grands tournois|main de dieu|knysna|battiston|squadra azzurra|oranje|teranga|diables rouges|finale (france|argentine) –|coup de tête en finale|contre l.argentine en 2018|contre la france en 2002|finale 2022|contre l.angleterre en 1986|avant 1998|victoire de 1998|avant chaque match en 1998|avec (l['’]|la |le |les )(espagne|france|argentine|portugal|allemagne|italie|brésil|pays-bas|angleterre)\b", re.I)
FIFA_CS = re.compile(r"\b(CAN|CAF|JO|Bleus)(?![\wÀ-ÿ])")
bad = lambda x: isinstance(x, str) and bool(FIFA_RX.search(x) or FIFA_CS.search(x))
clean = lambda qs: [q for q in qs if not any(map(bad, q))]
load = lambda f: json.load(open(os.path.join(src, f), encoding='utf-8'))

def write(name, var, data):
    with open(os.path.join(dst, name), 'w', encoding='utf-8') as f:
        f.write(f'const {var} = ' + json.dumps(data, ensure_ascii=False, separators=(',', ':')) + ';\n')

write('questions.js', 'QUESTIONS', {os.path.basename(p)[:-5]: clean(json.load(open(p, encoding='utf-8'))) for p in sorted(glob.glob(os.path.join(src, 'questions/*.json')))})
clubs = {k: {**c, 'q': clean(c['q'])} for k, c in load('clubs.json').items() if c.get('pays') not in ('wc', 'can')}
write('clubs.js', 'CLUBS', clubs)
write('derbies.js', 'DERBIES', [{**d, 'q': clean(d['q'])} for d in load('derbies.json')])
write('supporters.js', 'SUPPORTERS', [{**s, 'q': clean(s['q'])} for s in load('supporters.json')])
weeks = []
for w in load('semaine.json'):
    w = dict(w)
    w['q'] = clean(w.pop('app', None) or w['q'])
    w['intro'] = w.pop('introApp', None) or w.get('intro', '')
    assert len(w['q']) == 10 and not bad(w['intro']) and not bad(w['titre']), w['debut']  # validWeeks exige 10 questions
    weeks.append(w)
write('semaine.js', 'SEMAINE', weeks)
write('matchs.js', 'MATCHS', load('matchs.json'))
# contrôle : plus aucun terme retiré dans les fichiers produits
for f in ('questions.js', 'clubs.js', 'derbies.js', 'supporters.js', 'semaine.js'):
    t = open(os.path.join(dst, f), encoding='utf-8').read()
    assert not re.search(r'coupe du monde|mondial|fifa|sélection|copa am|\beuro\b', t, re.I), f
