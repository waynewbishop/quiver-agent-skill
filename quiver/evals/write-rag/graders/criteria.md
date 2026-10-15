---
type: llm
weight: 2
---

PASS if the code defines a struct conforming to Chunker (Quiver ships no concrete chunker) whose chunk(_:) returns [Chunk] (ideally via asChunks()), builds an EmbeddingIndex<Label> with init(embedder:), adds text with add(_:label:), calls retrieve(_:k:), and gates on RetrievalResult.isAboveGate(floor:outlierZ:) before using result.hits. No force unwraps.
FAIL if it assumes a built-in chunker type, invents a vector-store API (such as index.search or index.query), or uses no relevance gate.
