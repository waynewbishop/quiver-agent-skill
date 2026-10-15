---
type: llm
weight: 2
---

PASS if the Swift code uses Quiver's real API: it fits PCA on standardized data (either Pipeline.fit(features:labels:componentCount:k:) or StandardScaler.fit then PCA.fit(features:componentCount:)), reads explainedVarianceRatios (or explainedVariances), passes class labels with the labels: argument, uses no force unwraps, and does not wrap KNearestNeighbors, PCA, or StandardScaler fitting in try.
FAIL if it invents types or methods (such as a PCA(nComponents:) initializer, fitTransform, or a Matrix type), uses targets: for a classifier, or uses ! to force-unwrap.
