---
schema: 1
id: Mc3TaxEng3
memory_type: Context
title: Tax engine overview
status: accepted
date: 2026-09-01
summary: The tax engine computes VAT and sales tax per invoice line and validates buyer tax IDs.
last_confirmed: 2026-09-25
related: [relates_to::Mc1TaxIdR1]
applies_to: [topic:billing]
---

The billing service calls the tax engine once per invoice; a failed tax ID check blocks the invoice.
