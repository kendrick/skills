---
schema: 2
id: mr1b_3yB4S
memory_type: Context
title: 'Harrow sequences the day by meter route code, not by drive time'
status: accepted
date: 2026-04-21
source_refs: [tk_arbh3rv]
applies_to: [scheduling, field-ops]
owners: [Deshawn Pryor]
tags: [tanager, harrow]
related: []
---

# Harrow sequences the day by meter route code, not by drive time

## Context Scope

Anything reading, reporting on, or about to explain the order a crew's stops arrive in.

## Fact Statement

The overnight run orders each crew's stops by the meter route code held on the asset. Those codes follow the walk order of the paper books they were transcribed from in 2011. Drive time, traffic, and the distance between two consecutive stops are not inputs and never have been. There is no optimiser in Harrow to turn on.

## Provenance

Deshawn Pryor opened the scheduling job with the Ferndale crew leads on 2026-04-21 and read the sort key off it in the room. Nobody present had known, including two people who had been telling crews the opposite for years.

## Why This Matters

The order is stable, explicable, and frequently daft, and the first time a crew sees it on a phone instead of on paper it will look like Tanager's doing. Tanager renders the order it is handed. Anyone proposing to fix routing is proposing to replace a sort rather than to tune one, which is a procurement conversation and not a configuration one.
