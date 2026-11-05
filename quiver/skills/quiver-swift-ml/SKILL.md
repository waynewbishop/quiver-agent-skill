---
name: quiver-swift-ml
description: Writes and reviews Swift code that uses Quiver, the Swift library for statistics, linear algebra, and machine learning by Wayne Bishop. Use when a project imports Quiver or lists it in Package.swift, or when the user names Quiver, for example "write this with Quiver", "fit a Quiver model", "review my Quiver code", or "what changed in the latest Quiver release". Also use when reviewing or upgrading Quiver code to a newer release. Do not use in Core ML, Core AI, Create ML, or MLX projects, and never add Quiver to a project unless the user asks.
license: Apache-2.0
compatibility: Swift 5.9 or later; macOS 12, iOS 15, tvOS 15, watchOS 8, visionOS 1 or later.
metadata:
  quiver-coverage: "1.6.0"
---

# Quiver

## Baseline assumptions

- Quiver is a zero-dependency Swift package (`import Quiver`). Most of its API is extensions on `Array`: vectors are `[Double]`, feature tables are `[[Double]]` with one row per sample, class labels are `[Int]`. Models are value types such as `LinearRegression`, `KNearestNeighbors`, `PCA`, `EmbeddingIndex`, and `TrueEffortScore`.
- Do not add Quiver, or any other package, to a project unless the user asks. In Core ML, Core AI, Create ML, or MLX projects, use those frameworks instead.
- Never use force unwraps (`!`, `try!`) in Quiver code.

## Adding Quiver to a project

<!-- BEGIN GENERATED: install -->
Add Quiver only when the user asks for it, or asks for Quiver code in a project that doesn't have it yet. Confirm before editing `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/waynewbishop/quiver", from: "1.6.0")
],
targets: [
    .target(name: "App", dependencies: [.product(name: "Quiver", package: "quiver")])
]
```

In an Xcode app project, add the same URL with File > Add Package Dependencies.
<!-- END GENERATED: install -->

## Check the Quiver version first

<!-- BEGIN GENERATED: version -->
This skill covers Quiver 1.0.0 through 1.6.0. Before writing or reviewing code, read the project's `Package.resolved` (or the Quiver requirement in `Package.swift`) and find the Quiver version.

- Use only APIs available in that version. Reference entries tagged *(since X)* need Quiver X or later.
- If the project resolves a Quiver newer than 1.6.0, tell the user this skill covers Quiver through 1.6.0 and suggest updating the plugin. Treat any API not in the reference files as unknown rather than guessing.
- If no project is visible, assume Quiver 1.6.0 and say so, or ask which version the user is on.
<!-- END GENERATED: version -->

## Writing Quiver code

Before writing code, look up every Quiver API you use in the matching `reference/` file and copy its exact name and argument labels. Do not guess from NumPy, scikit-learn, or other libraries; Quiver's names differ. For a common task, start from the matching recipe in `cookbook.md`.

The rules most often broken (full list with explanations in `conventions.md`):

- `[Double] + [Double]` concatenates. Use `a.add(b)`, `a.subtract(b)`, `a.multiply(b)`, `a.divide(b)` for element-wise math, and `multiplyMatrix(_:)` for a matrix product.
- Statistics that can be undefined return optionals (`mean()`, `standardDeviation()`, `quartiles()`, `correlation(with:)`, `argMax()`, …). Unwrap with `if let`, or with `guard let` only inside a function. `summary()` returns `nil` for fewer than two values; use `mean()` for a single value.
- Write examples as top-level script code (`main.swift`, playground, notebook cell), where `return` does not compile. Use `if let` and `if`/`else`, not `guard ... else { return }`, unless the user's code is inside a function.
- Fits that solve or iterate throw (`LinearRegression`, `Ridge`, `GradientDescent`, `LogisticRegression`, and their `Pipeline` overloads). `KMeans`, `KNearestNeighbors`, `GaussianNaiveBayes`, `PCA`, and the scalers do not.
- Classifiers take `labels: [Int]`; regressors take `targets: [Double]`; `KMeans` takes `data:`.
- Standardize inputs to the iterative models: fit `GradientDescent` and `LogisticRegression` through `Pipeline`, and standardize `Ridge` features with a `StandardScaler`. Check `outcome` for `.converged` on all three.
- Supply an explicit `seed: UInt64` (or `using:` generator) wherever an API exposes one; a few, such as `KMeans.bestFit` and `oversample(labels:)`, take none. Use `stratifiedSplit(labels:testRatio:seed:)` for paired features and labels.
- Quiver ships the `Chunker` and `Embedder` protocols, not implementations; write a small conforming struct.
- For True Effort Score, read the True Effort Score section of `conventions.md` before writing any code.

## Reviewing Quiver code

1. Check every Quiver call against `reference/changes.md` for the project's version range. Flag renamed, removed, and changed APIs first, since that is where generated code most often fails.
2. Then check the code against `conventions.md`.

Report findings grouped by file. For each finding, name the rule broken and show the code before and after the fix. Report only genuine problems; do not report nitpicks or invent issues.

## When the build fails

Match the compiler message, fix the cause, and rebuild until there are no errors or warnings.

- `value of type '[Double]' has no member '…'`: the name was guessed from NumPy or another library. Find the real name in the matching `reference/` file.
- `value of optional type 'Double?' must be unwrapped`: the statistic returns an optional. Unwrap with `if let` (or `guard let` inside a function), never with `!`.
- `call can throw but is not marked with 'try'`: the fit throws. Wrap it in `do`/`catch` with `try`.
- `no calls to throwing functions occur within 'try' expression`: this fit does not throw. Remove the `try`.
- `return invalid outside of a func`: the code is top-level script code. Replace `guard … else { return }` with `if let` or `if`/`else`.
- No error, but a vector result is twice as long as expected: `+` concatenated two arrays. Use `a.add(b)`.

## Reference files

Read only the files the task needs. These files are generated by `scripts/generate-reference.swift`; never edit them by hand.

<!-- BEGIN GENERATED: reference-files -->
- `reference/changes.md`: breaking changes, behavior changes, and API diffs by release
- `reference/statistics.md`: descriptive statistics, the `Quartiles` type, skewness, empirical rule, frequency tables
- `reference/sampling.md`: train/test split, k-fold, resampling, bootstrap, sampling distributions
- `reference/charts.md`: data shaping for Swift Charts: `quartiles()`, histograms, bins, aggregation, cumulative and stacked series
- `reference/data.md`: `Panel`, panel summaries, contingency tables
- `reference/vectors.md`: dot products, norms, distances, similarity, matrix operations, angles, boolean masks, shape and info
- `reference/elementwise.md`: vector arithmetic, scalar broadcasting, element-wise functions
- `reference/linear-algebra.md`: matrix solve, LU, determinants, eigendecomposition, covariance, matrix and vector rendering
- `reference/regression.md`: `LinearRegression`, `Ridge`, `GradientDescent`, `ResidualModel`, coefficients, regression inference (`RegressionSummary`)
- `reference/classification.md`: `LogisticRegression`, `KNearestNeighbors`, `GaussianNaiveBayes`, distance metrics, and every evaluation metric on predictions (accuracy, confusion matrix, classification report, R², MSE, RMSE)
- `reference/preprocessing-clustering.md`: `Pipeline`, `StandardScaler`, `FeatureScaler`, `KMeans`, `PCA`
- `reference/tes.md`: `TrueEffortScore`: setup, the live recording loop, live readings, `finalize()`
- `reference/tes-results.md`: `TESResult`, `TESBaseline`, `EffortClass`, `EffortSignals`, `Workout`
- `reference/rag.md`: `Chunker`, `Embedder`, `EmbeddingIndex`, nearest-neighbor lookup, text tokenization
- `reference/signal-calculus.md`: Fourier transform, power spectrum, integration and derivatives, numerical Jacobian
- `reference/distributions.md`: probability distributions and Bayesian updating
- `reference/generation.md`: array generation, seeded random numbers, random distributions
- `reference/polynomial.md`: `Polynomial` and polynomial fitting
<!-- END GENERATED: reference-files -->
