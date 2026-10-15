---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [write]
---

My macOS app uses Quiver 1.6.0. Write Swift that splits a long document into paragraphs, stores the paragraphs in an on-device vector index, and retrieves the best paragraph for a user question, but only when the corpus actually covers the question. Assume I already have a type that conforms to Quiver's Embedder protocol.
