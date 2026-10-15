---
type: llm
weight: 2
---

PASS if the code holds TrueEffortScore in a var, calls record(heartRate:pace:cadence:grade:verticalOscillation:altitude:at:) with an absolute Date (not a time delta), unwraps finalize() with if let or guard let (it returns nil under 60 seconds of active time), treats meanResidual and baseline as optional on a first run, and persists with JSONEncoder (TrueEffortScore is Codable) or by saving history.
FAIL if it invents APIs (such as tes.start(), tes.addSample, a readiness score, or tes.score()), force-unwraps finalize(), or passes delta times.
