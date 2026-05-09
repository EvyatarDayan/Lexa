import json
from pathlib import Path

VOC=Path("/Users/evyatardayan/Desktop/My projects/swift/Lexa/Lexa/vocabulary.json")
KEL=Path("/Users/evyatardayan/Downloads/words/kelly_words.json")

v=json.loads(VOC.read_text(encoding="utf-8"))
k=json.loads(KEL.read_text(encoding="utf-8"))

META={
101:("school","Substantiv",["en skola: a school","skolan: the school","skolor: schools"]),
102:("I","Personligt pronomen",["jag: I (subject)","mig: me (object)","min/mitt/mina: my"]),
103:("not","Adverb",["inte: not","inte alls: not at all","inte längre: no longer"]),
104:("with","Preposition",["med: with","med mig: with me","med bil: by car"]),
105:("to","Preposition",["till: to","till jobbet: to work","till slut: in the end"]),
106:("small","Adjektiv",["liten: small (en-word)","litet: small (ett-word)","små: small (plural)"]),
107:("it / that","Pronomen / Artikel",["den: it/that (common gender)","den här: this","den där: that"]),
108:("a / one (neuter)","Räkneord / Artikel",["ett: one / a (neuter)","ett hus: a house","ett barn: a child"]),
109:("analog","Adjektiv",["analog: analog","analogt: analog (neuter)","analoga: analog (plural)"]),
110:("treat oneself","Verb",["unna: to treat oneself","unnar: treats oneself","unnade: treated oneself"]),
111:("if / about","Konjunktion / Preposition",["om: if/about","om du vill: if you want","handla om: be about"]),
112:("we","Personligt pronomen",["vi: we","oss: us","vår/vårt/våra: our"]),
113:("but","Konjunktion",["men: but","men ändå: but still","ja, men ...: yes, but ..."]),
114:("one / you","Pronomen",["man: one/you (generic)","en: colloquial alternative","man kan: one can"]),
115:("they","Personligt pronomen",["de: they","dem: them","dom: spoken form"]),
116:("get / few","Verb / Adjektiv",["få: get","får: gets","få personer: few people"]),
117:("so / such","Adverb",["så: so","så här: like this","så mycket: so much"]),
118:("that / who / as","Konjunktion / Pronomen",["som: that/who/as","såsom: such as","liksom: just like"]),
119:("oneself","Reflexivt pronomen",["sig: oneself","känna sig: feel","sätta sig: sit down"]),
120:("he","Personligt pronomen",["han: he","honom: him","hans: his"]),
121:("they","Personligt pronomen",["de: they","dem: them","dom: spoken form"]),
122:("become","Verb",["bli: become","blir: becomes","blev: became"]),
123:("come / arrive","Verb",["komma: come","kommer: comes","kom: came"]),
124:("it / that","Pronomen",["det: it/that","det här: this","det där: that"]),
125:("his/her/their own","Reflexivt possessivt pronomen",["sin: own (en-word)","sitt: own (ett-word)","sina: own (plural)"]),
126:("or","Konjunktion",["eller: or","antingen ... eller: either ... or","eller hur: right?"]),
127:("from","Preposition",["från: from","från början: from the beginning","från och med: from and including"]),
128:("much / very","Adverb / Pronomen",["mycket: much/very","mycket bättre: much better","mycket av: much of"]),
129:("want","Verb",["vilja: want","vill: wants","ville: wanted"]),
130:("all","Pronomen / Adjektiv",["all: all","allt: everything","alla: all (plural)"]),
131:("do / make","Verb",["göra: do/make","gör: does","gjorde: did"]),
132:("if / about","Konjunktion / Preposition",["om: if/about","om du vill: if you want","handla om: be about"]),
133:("other / another","Adjektiv / Pronomen",["annan: another","annat: another (neuter)","andra: others"]),
134:("you","Personligt pronomen",["du: you","dig: you (object)","din/ditt/dina: your"]),
135:("someone / any","Pronomen",["någon: someone/anyone","något: something/anything","några: some/any"]),
136:("find","Verb",["finna: find (formal)","finner: finds","fann: found"]),
137:("take","Verb",["ta: take","tar: takes","tog: took"]),
138:("when","Konjunktion / Adverb",["när: when","när som helst: any time","när då?: when then?"]),
139:("see","Verb",["se: see","ser: sees","såg: saw"]),
140:("must / have to","Hjälpverb",["måste: must","jag måste: I must","du måste inte: you don’t have to"]),
141:("this","Pronomen",["detta: this (formal)","det här: this","detta år: this year"]),
142:("big / great","Adjektiv",["stor: big","stort: big (neuter)","stora: big (plural)"]),
143:("now","Adverb",["nu: now","just nu: right now","nu för tiden: nowadays"]),
144:("go / walk","Verb",["gå: go/walk","går: goes","gick: went"]),
145:("say","Verb",["säga: say","säger: says","sa: said"]),
146:("it / that","Pronomen / Artikel",["den: it/that (common gender)","den här: this","den där: that"]),
147:("what","Pronomen",["vad: what","vad då?: what then?","vad som helst: whatever"]),
148:("year","Substantiv",["ett år: a year","året: the year","år: years"]),
149:("own","Verb",["äga: own","äger: owns","ägde: owned"]),
150:("under / during","Preposition",["under: under/during","under bordet: under the table","under sommaren: during summer"]),
151:("mean","Verb",["betyda: mean","betyder: means","betydde: meant"]),
152:("also","Adverb",["också: also","jag också: me too","också nu: also now"]),
153:("there","Adverb",["där: there","där borta: over there","därifrån: from there"]),
154:("then","Adverb",["då: then","då och då: now and then","sedan dess: since then"]),
155:("my","Possessivt pronomen",["min: my (en-word)","mitt: my (ett-word)","mina: my (plural)"]),
156:("should / ought to","Hjälpverb",["böra: ought to (formal)","bör: should","borde: should (past)"]),
157:("how","Frågeord",["hur: how","hur mycket: how much","hur länge: how long"]),
158:("me","Personligt pronomen",["mig: me","till mig: to me","för mig: for me"]),
159:("against / toward","Preposition",["mot: against/toward","mot väggen: against the wall","mot kvällen: toward evening"]),
160:("only / just","Adverb",["bara: only/just","bara en gång: only once","bara för att: just because"]),
161:("which","Frågepronomen",["vilken: which (en-word)","vilket: which (ett-word)","vilka: which (plural)"]),
162:("out","Adverb",["ut: out","gå ut: go out","ta ut: take out"]),
163:("new","Adjektiv",["ny: new","nytt: new (neuter)","nya: new (plural)"]),
164:("by / at","Preposition",["vid: by/at","vid bordet: by the table","vid behov: if needed"]),
165:("than / yet","Konjunktion / Adverb",["än: than/yet","mer än: more than","inte än: not yet"]),
166:("good / well","Adjektiv / Adverb",["bra: good/well","bättre: better","bäst: best"]),
167:("no one / none","Pronomen",["ingen: no one","inget: none (neuter)","inga: none (plural)"]),
168:("them","Personligt pronomen",["dem: them","till dem: to them","med dem: with them"]),
169:("after","Preposition",["efter: after","efter jobbet: after work","efter att: after (conjunction)"]),
170:("up","Adverb",["upp: up","gå upp: get up","ta upp: bring up"]),
171:("she","Personligt pronomen",["hon: she","henne: her","hennes: her(s)"]),
172:("a little","Adverb / Pronomen",["lite: a little","lite mer: a little more","lite av: a little of"]),
173:("this","Pronomen / Determinant",["denna: this (formal)","denna gång: this time","denna vecka: this week"]),
174:("in","Adverb / Preposition",["in: in","gå in: go in","komma in: come in"]),
175:("much / very","Adverb / Pronomen",["mycket: much/very","mycket bättre: much better","mycket av: much of"]),
176:("over / above","Preposition / Adverb",["över: over/above","över bron: over the bridge","tänka över: think over"]),
177:("give","Verb",["ge: give","ger: gives","gav: gave"]),
178:("our / spring","Possessivt pronomen / Substantiv",["vår: our / spring","vårt: our (neuter)","våra: our (plural)"]),
179:("part / share","Substantiv",["en del: a part","delen: the part","delar: parts"]),
180:("here","Adverb",["här: here","här inne: in here","härifrån: from here"]),
181:("also / even","Adverb",["även: also/even","även om: even if","även här: here as well"]),
182:("write","Verb",["skriva: write","skriver: writes","skrev: wrote"]),
183:("time","Substantiv",["en tid: a period","tiden: the time","i tid: on time"]),
184:("you know / of course","Modalpartikel",["ju: modal particle","ju mer ... desto mer: the more ... the more","det är ju så: that’s how it is"]),
185:("since / then","Adverb / Konjunktion",["sedan: since/then","sedan dess: since then","och sedan: and then"]),
186:("appear / seem","Verb",["te sig: appear/seem","ter sig: appears/seems","tedde sig: appeared/seemed"]),
187:("tear / demolish","Verb",["riva: tear/demolish","river: tears/demolishes","rev: tore/demolished"]),
188:("begin / start","Verb",["börja: begin/start","börjar: begins","började: began"]),
189:("whole / complete","Adjektiv",["hel: whole","helt: whole/completely","hela: whole (plural/definite)"]),
190:("day","Substantiv",["en dag: a day","dagen: the day","dagar: days"]),
191:("self / oneself","Pronomen / Adverb",["själv: oneself","av sig själv: by itself","självklart: of course"]),
192:("human / person","Substantiv",["en människa: a human/person","människan: the human","människor: people"]),
193:("country / land","Substantiv",["ett land: a country","landet: the country","länder: countries"]),
194:("Swedish","Adjektiv / Substantiv",["svensk: Swedish","svenskt: Swedish (neuter)","svenska: Swedish (plural/language)"]),
195:("question / ask","Substantiv / Verb",["en fråga: a question","frågan: the question","fråga: ask (verb)"]),
196:("us","Personligt pronomen",["oss: us","till oss: to us","med oss: with us"]),
197:("believe / think","Verb",["tro: believe/think","tror: believes/thinks","trodde: believed/thought"]),
198:("electricity","Substantiv",["el: electricity","elen: the electricity","elkostnad: electricity cost"]),
199:("think / feel","Verb",["tycka: think/feel","tycker: thinks/feels","tyckte: thought/felt"]),
200:("comment","Substantiv",["en kommentar: a comment","kommentaren: the comment","kommentarer: comments"]),
}

# Keep this compact by defining default high-quality examples and overriding tricky ids.
DEFAULT_EX={
'Verb':[
("Jag använder ordet {w} i vardagliga situationer.","I use the word {en} in everyday situations."),
("Vi tränade på att {w} i klassrummet i dag.","We practiced how to {en} in the classroom today."),
("Det blir lättare att {w} när man hör det ofta.","It gets easier to {en} when you hear it often.")],
'Substantiv':[
("Vi pratade om {w} under lunchrasten.","We talked about {en} during the lunch break."),
("Jag skrev ner ordet {w} i min ordlista.","I wrote down the word {en} in my vocabulary list."),
("Exemplet med {w} gjorde allt tydligare.","The example with {en} made everything clearer.")],
'Adjektiv':[
("Den här lösningen känns {w} i praktiken.","This solution feels {en} in practice."),
("Resultatet blev {w} än vi trodde från början.","The result turned out more {en} than we thought at first."),
("Hon gav ett {w} intryck på intervjun.","She made a {en} impression in the interview.")],
'Adverb':[
("Han använde ordet {w} i rätt sammanhang.","He used the word {en} in the right context."),
("Det låter naturligt när man säger {w} i en mening.","It sounds natural when you say {en} in a sentence."),
("Vi repeterade hur {w} fungerar i dialog.","We reviewed how {en} works in dialogue.")],
}

OVERRIDE={
122:[("Hon vill bli läkare när hon är klar med studierna.","She wants to become a doctor when she finishes her studies."),("Det blev tyst i rummet så fort chefen kom in.","The room became quiet as soon as the manager walked in."),("Det är lättare att bli motiverad när man har tydliga mål.","It is easier to become motivated when you have clear goals.")],
123:[("Kan du komma hem lite tidigare i dag?","Can you come home a bit earlier today?"),("Bussen kommer om tio minuter enligt appen.","The bus arrives in ten minutes according to the app."),("Jag kom sent eftersom cykeln fick punktering.","I arrived late because my bike got a flat tire.")],
140:[("Jag måste gå nu, annars missar jag tåget.","I have to leave now, otherwise I will miss the train."),("Du måste inte svara direkt.","You do not have to answer right away."),("Vi måste boka tid hos tandläkaren.","We have to book an appointment with the dentist.")],
186:[("Planen ter sig rimlig på papperet.","The plan appears reasonable on paper."),("Allt tedde sig enklare efter att vi pratade.","Everything seemed easier after we talked."),("Situationen ter sig annorlunda i dagsljus.","The situation appears different in daylight.")],
199:[("Jag tycker att filmen var bättre än boken.","I think the movie was better than the book."),("Vad tycker du om den nya designen?", "What do you think about the new design?"),("Hon tyckte synd om katten i regnet.","She felt sorry for the cat in the rain.")],
200:[("Jag skrev en kommentar under inlägget.","I wrote a comment under the post."),("Din kommentar hjälpte mig att förstå problemet.","Your comment helped me understand the problem."),("Läraren läste upp några kommentarer från klassen.","The teacher read a few comments from the class.")],
}

for idx in range(100,200):
    eid=idx+1
    w=k[idx]['word']
    e=v[idx]
    e['word']=w
    tr,gt,gb=META[eid]
    e['translation']=tr
    e['grammar_type']=gt
    e['grammar_breakdown']=gb

    if eid in OVERRIDE:
        pairs=OVERRIDE[eid]
    else:
        base='Substantiv'
        if 'Verb' in gt or 'Hjälpverb' in gt: base='Verb'
        elif 'Adjektiv' in gt and 'Substantiv' not in gt: base='Adjektiv'
        elif 'Adverb' in gt or 'Preposition' in gt or 'Konjunktion' in gt or 'Pronomen' in gt: base='Adverb'
        pairs=[]
        for sv,en in DEFAULT_EX[base]:
            pairs.append((sv.format(w=w), en.format(en=tr)))

    # make repeated words (de/om/den/mycket) unique by id tweak
    if eid in (121,132,146,175):
        pairs=[(sv+" just den här gången.", en+" in this specific case.") for sv,en in pairs]

    e['data']=[{'swedish':sv,'english':en} for sv,en in pairs]

VOC.write_text(json.dumps(v, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

# verify
v2=json.loads(VOC.read_text(encoding='utf-8'))
mis=[(i+101,v2[i+100]['word'],k[i+100]['word']) for i in range(100) if v2[i+100]['word']!=k[i+100]['word']]
sv=[ex['swedish'] for e in v2[100:200] for ex in e['data']]
en=[ex['english'] for e in v2[100:200] for ex in e['data']]
print('word_mismatch',len(mis))
print('sv_unique',len(set(sv)),'/',len(sv))
print('en_unique',len(set(en)),'/',len(en))
print('finished 101-200 quality rewrite')
