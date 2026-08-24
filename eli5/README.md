# eli5

A skill that makes the agent say that again, plainly.

## Why This Exists

Sometimes an agent's answer is right and the sentence still doesn't land: three clauses deep, wearing the vocabulary of whatever doc it just read. You could type "explain that more simply," but you'd be writing the same corrective prompt for the hundredth time. `/eli5` is that prompt, saved.

It's a mashup of two upstream one-liners. [`bro`](https://github.com/cursor/plugins/blob/main/pstack/skills/bro/SKILL.md), from Lauren Tan's pstack in cursor/plugins, supplies the register: "more simply and concisely, like one human talking to another." [`wait-what`](https://github.com/mattpocock/skills/blob/main/skills/productivity/wait-what/SKILL.md), from Matt Pocock's skills, supplies the discipline: re-pitch with a little context, in ASD-STE100 Simplified Technical English. Both are MIT licensed. This skill keeps those two halves and drops wait-what's lookup of repo-specific vocabulary files, which belongs to Matt's setup rather than yours.

## How It Works

Bare `/eli5` re-pitches the whole last response, including what the tool activity concluded, not just the closing prose. `/eli5 <text>` re-pitches just that part, in the context of the response it came from.

The restatement follows a distilled ASD-STE100: materially shorter than the original, one idea per sentence, imperative mood for anything you should do, one meaning per word, active voice. The rules are the means and plain human talk is the goal, so when a rule would make a sentence sound robotic, the human register wins. And the re-pitch invents nothing. It can offer a concrete example, but only one that illustrates a claim the original already made.

## Install

```bash
npx skills add kendrick/skills --skill eli5
```

Or by hand:

```bash
git clone git@github.com:kendrick/skills.git
cp -R skills/eli5 ~/.claude/skills/eli5
```

## Use

```
> /eli5
> /eli5 the part about cache invalidation
```

It fires only when you type it—the agent can't invoke it on its own—because you're the judge of what didn't land.

If your fingers still type the old name, alias it: `ln -s eli5 ~/.claude/skills/huh`.

## License

MIT, per the [collection license](../LICENSE). This skill is part of the [skills collection](..). Both upstream sources are MIT: `bro` under [pstack's license](https://github.com/cursor/plugins/blob/main/pstack/LICENSE), `wait-what` under [mattpocock/skills'](https://github.com/mattpocock/skills/blob/main/LICENSE).
