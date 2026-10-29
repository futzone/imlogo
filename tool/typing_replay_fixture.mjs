// Tez yozish bosishlar logining qayta o'ynalishi sayt (server) bilan bir xil
// ekanini tekshirish uchun fixture yasaydi: `test/fixtures/typing_replay_cases.json`.
//
//   node tool/typing_replay_fixture.mjs [sayt-repozitoriyasi]
//
// Saytdagi `src/lib/app/typing/*.ts` (server ham aynan shu kodni ishlatadi)
// TypeScript bilan kompilyatsiya qilinadi va tasodifiy yozish loglari
// (odam, script, bir yo'la kiritish) shu kod bilan qayta o'ynaladi.
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const site = process.argv[2] ?? join(root, '..', 'imlogo-uz');
const output = join(root, 'test', 'fixtures', 'typing_replay_cases.json');

const require = createRequire(join(site, 'package.json'));
const ts = require('typescript');
const build = mkdtempSync(join(tmpdir(), 'typing-fixture-'));
for (const name of ['config', 'engine', 'text', 'compose', 'input', 'guard', 'replay', 'result', 'words']) {
    const source = readFileSync(join(site, 'src/lib/app/typing', `${name}.ts`), 'utf8')
        .replace(/@\/lib\/translit\/core/g, './core')
        .replace(/@\/lib\/translit\/lexicon/g, './core');
    const { outputText } = ts.transpileModule(source, {
        compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
    });
    writeFileSync(join(build, `${name}.js`), outputText);
}
// Yozuvlar orasida o'girish bu testga kerak emas (so'zlar tayyor beriladi).
writeFileSync(join(build, 'core.js'), 'module.exports = { transliterate: s => s, loadLexicon: async () => null };');
const load = name => createRequire(join(build, 'x.js'))(`./${name}.js`);
const { replayTypingLog } = load('replay');
const { analyzeTyping } = load('guard');
const { typingResultFromEngine } = load('result');
const { applyTypingValue } = load('input');
const { TypingEngine } = load('engine');
const { createWordGenerator, createSentenceWords, parseWordList, parseSentenceList } = load('words');

// Doimiy urug'li tasodif — fixture har safar bir xil chiqadi.
let seed = 7;
const random = () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
Math.random = random;
const logNormal = (mean, cv) => {
    const sigma = Math.sqrt(Math.log(1 + cv * cv));
    const mu = Math.log(mean) - (sigma * sigma) / 2;
    return Math.exp(mu + sigma * Math.sqrt(-2 * Math.log(1 - random())) * Math.cos(2 * Math.PI * random()));
};

const toYangi = word => word.replace(/sh/g, 'ş').replace(/ch/g, 'ç').replace(/o'/g, 'ö').replace(/g'/g, 'ğ');
const latinWords = parseWordList(readFileSync(join(site, 'public/words/uz.txt'), 'utf8'));
const latinSentences = parseSentenceList(readFileSync(join(site, 'public/words/uz-sentences.txt'), 'utf8')).slice(0, 400);
const DIGRAPHS = { ş: 'sh', ç: 'ch', ö: "o'", ğ: "g'", Ş: 'Sh', Ç: 'Ch', Ö: "O'", Ğ: "G'" };

const wordsFor = config => {
    const yangi = config.alphabet === 'yangi';
    if (config.mode === 'sentences') {
        return createSentenceWords(yangi ? latinSentences.map(toYangi) : latinSentences, config.amount);
    }
    const next = createWordGenerator(yangi ? latinWords.map(toYangi) : latinWords, config);
    const count = config.mode === 'words' ? config.amount : Math.ceil(config.amount * 5) + 60;
    return Array.from({ length: count }, next);
};

/** Ilovadagi kabi yozadi: maydon har doim dvigateldagi joriy so'zni ko'rsatadi. */
const simulate = (config, words, profile) => {
    const engine = new TypingEngine(config, words);
    const state = { pending: null };
    const log = [];
    let clock = 0;
    let started = null;
    const push = (value, it, k) => {
        const t = started === null ? 0 : Math.round((clock - started) * 10) / 10;
        log.push({ t, v: value, it, k });
        applyTypingValue(engine, state, value, t);
        if (engine.started && started === null) started = clock;
    };
    for (let guard = 0; guard < 20000 && !engine.finished && engine.target !== undefined; guard++) {
        clock += profile.delay();
        if (config.mode === 'time' && started !== null && clock - started >= config.amount * 1000) break;
        const target = engine.target;
        const current = engine.current;
        const wrong = [...current].findIndex((ch, i) => ch !== target[i]);
        const key = profile.keyed() ? 'x' : null;
        if (profile.multi && random() < profile.multi && current.length < target.length) {
            push(current + target.slice(current.length), 'insertText', key);
            continue;
        }
        if ((wrong >= 0 || current.length > target.length) && random() < 0.9) {
            if (current === '' && random() < 0.5) push(null, 'deleteContentBackward', key);
            else push(current.slice(0, -1), 'deleteContentBackward', key);
            continue;
        }
        if (current.length >= target.length) {
            push(current + ' ', 'insertText', key);
            continue;
        }
        let ch = target[current.length];
        if (random() < profile.error) ch = 'qwxz'[Math.floor(random() * 4)];
        const digraph = config.alphabet === 'yangi' && DIGRAPHS[ch] && random() < 0.7 ? DIGRAPHS[ch] : null;
        if (digraph) {
            push(current + digraph[0], 'insertText', key);
            // Birinchi belgi oxirgi so'zni yakunlagan bo'lishi mumkin.
            if (engine.finished || engine.target === undefined) break;
            clock += profile.delay();
            push(engine.current + digraph[1], 'insertText', key);
        } else {
            push(current + ch, 'insertText', key);
        }
    }
    return log;
};

const profiles = {
    human: { delay: () => logNormal(190, 0.5), error: 0.04, keyed: () => true },
    slow: { delay: () => logNormal(420, 0.6), error: 0.06, keyed: () => true },
    bot: { delay: () => 100 + random() * 2, error: 0, keyed: () => true },
    paste: { delay: () => logNormal(200, 0.5), error: 0.02, keyed: () => random() < 0.6, multi: 0.15 },
};
const configs = [];
for (const alphabet of ['lotin', 'yangi']) {
    configs.push({ mode: 'time', amount: 15, punctuation: false, numbers: false, alphabet });
    configs.push({ mode: 'time', amount: 30, punctuation: true, numbers: true, alphabet });
    configs.push({ mode: 'words', amount: 10, punctuation: false, numbers: false, alphabet });
    configs.push({ mode: 'words', amount: 25, punctuation: true, numbers: false, alphabet });
    configs.push({ mode: 'sentences', amount: 3, punctuation: false, numbers: false, alphabet });
}

const cases = [];
for (const config of configs) {
    for (const [name, profile] of Object.entries(profiles)) {
        const words = wordsFor(config);
        const log = simulate(config, words, profile);
        const replay = replayTypingLog(config, words, log);
        const finished = replay.engine.finished;
        const result = finished ? typingResultFromEngine(replay.engine) : null;
        cases.push({
            name: `${config.alphabet} ${config.mode} ${config.amount} ${name}`,
            config,
            words,
            log,
            expected: {
                finished,
                flags: result ? analyzeTyping(replay.events, result.wpm) : [],
                result: result && {
                    wpm: result.wpm,
                    raw: result.raw,
                    accuracy: result.accuracy,
                    consistency: result.consistency,
                    correctChars: result.correctChars,
                    incorrectChars: result.incorrectChars,
                    extraChars: result.extraChars,
                    missedChars: result.missedChars,
                    seconds: result.seconds,
                    samples: result.samples.map(s => [s.second, s.wpm, s.raw, s.errors]),
                },
            },
        });
    }
}
writeFileSync(output, JSON.stringify(cases));
const flagged = cases.filter(c => c.expected.flags.length).length;
console.log(`${cases.length} ta holat (${flagged} tasi bayroqli) yozildi: ${output}`);
