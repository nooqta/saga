# SAGA — A Claude Code Plugin

*Structured Agile Governance Agent*

---

## Who's Behind This

As an indie hacker, I kept starting projects, getting lost in the code, and forgetting which feature was supposed to do what. Needed a way to ship faster without losing track.

Found [Geoffrey Huntley's Ralph Wiggum loop](https://ghuntley.com/ralph/) and [Ryan Carson's workflow](https://github.com/snarktank/ralph). Game changer. But I wanted something I could just run inside Claude Code without copying bash scripts around.

So I made this. It's not a replacement for Ryan's ralph — that works great. This is just how I like to work: everything inside Claude Code, with some extra tracking so I don't lose my mind on bigger projects.

---

## What's This?

SAGA runs the Ralph loop as a Claude Code plugin. No terminal scripts. No jq. Just `/saga` commands.

I added SRS (structured requirements) instead of PRD because I kept forgetting what my own features were supposed to do. Now everything has an ID and I can actually trace what code does what.

## The Ralph Thing

If you don't know Ralph, here's the gist from [Geoffrey Huntley](https://www.youtube.com/watch?v=4Nna09dG_c0):

```bash
while :; do cat PROMPT.md | claude ; done
```

Run AI in a loop. Each iteration is fresh. Memory lives in files — git commits, progress logs. Define what "done" looks like, let it figure out how.

Geoffrey's insight: **"LLMs are amplifiers of operator skill."** When it fails, you don't blame the tool. You add better instructions. Failure is data.

Ryan Carson ships features while sleeping — three Ralph instances, three branches, three features. That's the dream.

## How I Use It

My daily:

1. **Morning** — `/saga init` on a new idea, spend 20 mins on `/saga spec` really thinking through what I want
2. **Let it run** — `/saga execute` while I do other stuff
3. **Check gaps** — `/saga trace` to see what's covered, `/saga gaps` to see what's not
4. **Tune** — When something breaks, I add notes to the spec. That's the "signs" thing Geoffrey talks about.

For my simple projects, PRD would be fine. But I'm building stuff I want to maintain, maybe sell someday. So I use SRS — numbered requirements, traceable stories. When I come back in 2 weeks, I actually know what's going on.

## Quick Start

```bash
/saga init        # setup
/saga spec        # think through requirements
/saga plan        # create stories
/saga execute     # run the loop
```

## SAGA vs Ryan's Ralph

Not better. Different use case.

| | ralph | SAGA |
|--|-------|------|
| **Setup** | Copy scripts, install jq | `/plugin install` |
| **Run** | Terminal: `./ralph.sh` | Inside Claude: `/saga execute` |
| **Format** | PRD | SRS |
| **Best for** | Quick features | Projects you'll maintain |

Use Ryan's ralph if you like working in terminal. Use SAGA if you want everything inside Claude Code.

## The Workflow

**1. Spec first** — The better your requirements, the better the output. I spend real time here.

**2. Small stories** — Each one fits in a context window. "Build auth" is too big. "Add email validation" is right.

**3. Fast feedback** — Tests matter. Without them, broken code compounds.

**4. Tune with signs** — It will fail. Add instructions. Try again. That's the process.

## Commands

| Command | What |
|---------|------|
| `/saga init` | Setup |
| `/saga spec` | Requirements |
| `/saga plan` | Stories |
| `/saga execute` | Run loop |
| `/saga status` | Progress |
| `/saga trace` | Coverage |
| `/saga gaps` | What's missing |

## Install

```bash
/plugin marketplace add nooqta/saga
/plugin install saga@nooqta-saga
```

That's it.

## Requirements

Just Claude Code CLI. That's it.

## PM Sync

Optional GitHub/GitLab integration. Creates issues, closes them when done, makes PRs. Set up during `/saga init` if you want it.

## Optional: Stitch AI

Building UI? [Stitch AI](https://stitch.withgoogle.com/docs/mcp/setup/) adds design memory. I use it sometimes. Totally optional.

## Credits

- [Ralph Wiggum loop](https://ghuntley.com/ralph/) — Geoffrey Huntley
- [ralph](https://github.com/snarktank/ralph) — Ryan Carson
- [Ralf](https://github.com/anis-marrouchi/ralf) — my earlier attempt at this
- Built by [Nooqta](https://github.com/nooqta)

## License

MIT

---

*Still figuring this out. If you try it and have ideas, [open an issue](https://github.com/nooqta/saga/issues).*
