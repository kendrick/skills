Name the tags/themes mixup instead of its symptom

A record carrying every key in its order, `tags` and `themes` included, closes its frontmatter on line 21. The lint reported `frontmatter-budget`, so whoever read it went looking for a key to delete. The overrun is the symptom; the cause is a journal entry's key sitting on a record, and nothing in the output said so.

`frontmatter-key-domain` fires on the co-presence of both keys and names both in the message. It sits ahead of the budget guard because `check_frontmatter` returns at the first failure it hits, and every file this check exists for is 21 lines—behind the guard it would never run at all.

The contract fed the confusion. It claimed both key orders fit the budget with room to spare, so an overrun read as accumulated commented-out keys rather than real content. The note order does have a spare line. The record order has none: with `tags` and `themes` mutually exclusive it tops out at 18 keys and closes on exactly line 20.

The check fires on co-presence only. A record carrying `tags` alone and a journal entry carrying `themes` alone both stay legal, since rejecting `themes` on a non-journal record goes past what the issue asked for.

Closes #28
