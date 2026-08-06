---
schema: 2
id: WJicoHVdFw
memory_type: Decision
title: 'The vendor lock window stays open for thirty days after cutover'
status: accepted
date: 2026-02-20
last_confirmed: 2026-02-20
source_refs: [oKZJNnBgR5]
applies_to: [vendor-selection]
owners: [Marcus Dell]
tags: [vendor]
---

# The vendor lock window stays open for thirty days after cutover

## Decision

Northwind can swap vendors without penalty for thirty days past cutover.

## Alternatives Discarded

Closing the window at cutover, which was cheaper on paper and left no room to discover a vendor problem under real load.

## Why

This fixture exists so a contradiction flag in this scope has something accepted to point at. It carries no defect of its own.
