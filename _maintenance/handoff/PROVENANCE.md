# Handoff Provenance

| Fetch date | Run | harpb | mattpocock |
| --- | --- | --- | --- |
| 2026-07-24 | Initial snapshot | Gist revision `2d08a2c47b6fe2443547061fe18494528eafa793`, updated `2026-07-24T04:32:29Z`; <https://gist.githubusercontent.com/harpb/3f4ff1899db04a0957c66634ca549292/raw/handoff.md> | Commit `386d4ff719a7c420ad1454232d0436b01f1b8c17`; <https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/handoff/SKILL.md> |

## Deviations From Upstream

The local template keeps the upstream write and resume loop but makes these deliberate changes:

- It stores handoff files in the OS temp directory, namespaced by project (`<TMP>/agent-handoff/<project-slug>/`), and uses each host's task or plan mechanism when available.
- Storage now converges with mattpocock's "Save to the temporary directory of the user's OS - not the current workspace", which the initial merge rejected in favour of a repository folder. The template arrived at the same place independently, on durability and cleanliness grounds rather than by adopting upstream.
- It removes harpb's repository-specific exceptions and service names.
- It keeps the merged skill in `template/SKILL.md`; `sync-upstream.mjs --write` emits the shipped `handoff/SKILL.md` only after upstream checks pass.

Record later differences from either upstream here before updating snapshots or the template.
