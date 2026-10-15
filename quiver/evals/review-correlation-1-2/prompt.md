---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [review]
---

This file, Trend.swift, was written against Quiver 1.2.0. We're upgrading to Quiver 1.6.0. Review it and show what must change.

```swift
import Quiver

// Reports whether pace and heart rate move together.
func trend(pace: [Double], heartRate: [Double]) -> String {
    let r = pace.correlation(with: heartRate)
    return r > 0.5 ? "strongly linked" : "weakly linked"
}
```
