---
type: llm
weight: 2
---

PASS if the code calls LogisticRegression.fit(features:labels:...) or Pipeline.fit(features:labels:learningRate:...) with try inside do/catch (or a throwing function), standardizes the features (Pipeline or StandardScaler) and transforms the new row with the same fitted scaler, checks that outcome is .converged, and gets the probability with predictProbabilities on the model (through pipeline.model when a Pipeline is used, after pipeline.scaler.transform). No force unwraps.
FAIL if it calls predictProbabilities directly on a Pipeline, fits a fresh scaler on the query row, uses targets: for the labels, or omits try.
