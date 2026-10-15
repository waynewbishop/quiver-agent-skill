---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [review]
---

We're moving this project from Quiver 1.5.0 to 1.6.0. Review Metric.swift for anything the upgrade affects.

```swift
import Quiver

// Returns a display name for the distance metric a model uses.
func name(for metric: DistanceMetric) -> String {
    switch metric {
    case .euclidean: return "Euclidean"
    case .cosine: return "Cosine"
    default: return "Euclidean"
    }
}
```
