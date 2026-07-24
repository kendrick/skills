#!/usr/bin/env node
// Compare upstream snapshots and render the reviewed local skill on any Node 18+ host.
import { mkdtemp, readFile, rm, writeFile, copyFile, mkdir } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const snapshotDir = path.join(scriptDir, "upstream");
const templatePath = path.join(scriptDir, "template", "SKILL.md");
const defaultOutputPath = path.resolve(scriptDir, "..", "..", "handoff", "SKILL.md");
const sources = [
  {
    name: "harpb-handoff.md",
    url: "https://gist.githubusercontent.com/harpb/3f4ff1899db04a0957c66634ca549292/raw/handoff.md",
  },
  {
    name: "mattpocock-SKILL.md",
    url: "https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/handoff/SKILL.md",
  },
];

function usage() {
  console.log(`Usage: sync-upstream [--check | --write] [--skip-upstream] [--output <path>]

  --check          Report upstream or generated-skill drift without writing (default).
  --write          Render the canonical template after upstream checks pass.
  --skip-upstream  Skip network checks; useful for local render checks and tests.
  --output <path>  Check or write a different generated-skill path.`);
}

function parseArgs(argv) {
  const options = { mode: "check", skipUpstream: false, outputPath: defaultOutputPath };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--check") {
      options.mode = "check";
    } else if (argument === "--write") {
      options.mode = "write";
    } else if (argument === "--skip-upstream") {
      options.skipUpstream = true;
    } else if (argument === "--output") {
      const output = argv[index + 1];
      if (!output) throw new Error("--output requires a path");
      options.outputPath = path.resolve(process.cwd(), output);
      index += 1;
    } else if (argument === "--help" || argument === "-h") {
      usage();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${argument}`);
    }
  }

  return options;
}

function showDiff(before, after) {
  const result = spawnSync("git", ["diff", "--no-index", "--", before, after], {
    encoding: "utf8",
  });

  if (result.error) throw result.error;
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.status > 1) throw new Error(`git diff failed with exit code ${result.status}`);
}

async function fetchSource(source, destination) {
  const response = await fetch(source.url);
  if (!response.ok) throw new Error(`Could not fetch ${source.name}: ${response.status} ${response.statusText}`);
  await writeFile(destination, new Uint8Array(await response.arrayBuffer()));
}

async function compareUpstreams() {
  const temporaryDir = await mkdtemp(path.join(os.tmpdir(), "handoff-upstream-"));

  try {
    const results = await Promise.all(sources.map(async (source) => {
      const snapshot = path.join(snapshotDir, source.name);
      const fresh = path.join(temporaryDir, source.name);
      await fetchSource(source, fresh);
      const [snapshotContents, freshContents] = await Promise.all([readFile(snapshot), readFile(fresh)]);

      if (Buffer.compare(snapshotContents, freshContents) === 0) {
        console.log(`No upstream changes: ${source.name}`);
        return false;
      }

      showDiff(snapshot, fresh);
      console.error(`Upstream changed: ${source.name}`);
      return true;
    }));

    return results.some(Boolean);
  } finally {
    await rm(temporaryDir, { recursive: true, force: true });
  }
}

async function renderSkill(options) {
  const template = await readFile(templatePath);
  let current;

  try {
    current = await readFile(options.outputPath);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  if (options.mode === "write") {
    await mkdir(path.dirname(options.outputPath), { recursive: true });
    await copyFile(templatePath, options.outputPath);
    console.log(`Rendered skill: ${options.outputPath}`);
    return true;
  }

  if (current && Buffer.compare(template, current) === 0) {
    console.log(`Generated skill is current: ${options.outputPath}`);
    return true;
  }

  console.error(`Generated skill differs from the canonical template: ${options.outputPath}`);
  if (current) showDiff(templatePath, options.outputPath);
  return false;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const upstreamChanged = options.skipUpstream ? false : await compareUpstreams();

  if (upstreamChanged) {
    console.error("Review upstream changes and update the template deliberately before rendering.");
    process.exitCode = 1;
    return;
  }

  if (!(await renderSkill(options))) process.exitCode = 1;
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
