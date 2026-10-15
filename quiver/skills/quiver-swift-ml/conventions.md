# Quiver conventions and traps

Hand-written. Each rule below is a mistake that is easy to make with Quiver and has been checked against Quiver 1.6.0. Signatures live in `reference/`; this file explains how to use them correctly.

## Data shapes

- Quiver has no `Vector`, `Matrix`, or `DataFrame` type. A vector is `[Double]`, a matrix or feature table is `[[Double]]` (one row per sample), class labels are `[Int]`, and regression targets are `[Double]`. Do not invent wrapper types. `Panel` is the one columnar container; use it only when the user is working with named columns.
- `[Double] + [Double]` uses Swift's own `+`, which **concatenates** the arrays: `[1, 2] + [3, 4]` is `[1, 2, 3, 4]`. For element-wise math, call `a.add(b)`, `a.subtract(b)`, `a.multiply(b)`, or `a.divide(b)`. Quiver's operators only broadcast a scalar: `vector * 2.0`, `vector + 1.0`.
- `[[Double]].multiply(_:)` is element-wise. The matrix product is `multiplyMatrix(_:)`. A dot product is `dot(_:)`.

## Optionals versus throws

- Statistics that can be undefined return an optional rather than `NaN`: `mean()`, `median()`, `variance()`, `standardDeviation()`, `quartiles()`, `percentile(_:)`, `zScore(of:)`, `correlation(with:)`, `argMin()`, `argMax()`, and others. `nil` means "undefined for this data" (empty input, zero variance), not an error. Unwrap with `guard let` or `if let`, and never with `!`.
- `correlation(with:)` returns `Double?` from 1.2.5 on. A constant vector gives `nil`.
- Fitting a model that solves or iterates throws: `LinearRegression.fit`, `Ridge.fit`, `GradientDescent.fit`, `LogisticRegression.fit`, the `Pipeline.fit` overloads for those models, `inverted()`, and `TrueEffortScore(history:labeledSamples:labels:)`. Call these with `try` inside `do`/`catch`.
- `KMeans.fit`, `KNearestNeighbors.fit`, `GaussianNaiveBayes.fit`, `PCA.fit`, `StandardScaler.fit`, `FeatureScaler.fit`, and their `Pipeline.fit` overloads do not throw. Do not wrap them in `try`.
- When unsure, read the declaration in `reference/`: a `?` on the return type means unwrap, and `throws` means `try`.

## Fitting models

- Models are value types created by a static `fit`. There is no `init()` followed by `train()`, and no unfitted state to check. The exceptions: `ResidualModel(model:)` wraps an already-fitted regressor, and `TrueEffortScore` is a mutable model held in a `var` (see below).
- Classifiers take `labels: [Int]`: `KNearestNeighbors`, `GaussianNaiveBayes`, `LogisticRegression`. Regressors take `targets: [Double]`: `LinearRegression`, `Ridge`, `GradientDescent`. Do not swap them.
- `KMeans.fit(data:k:seed:)` takes `data:`, not `features:`. Its cluster numbers are arbitrary; never assume cluster 0 is the first group.
- `GradientDescent` and `LogisticRegression` are the two iterative models where feature scale changes the result. Standardize their inputs, preferably by fitting through `Pipeline`. The default `learningRate` of `0.01` is deliberately conservative and can hit the 1,000-iteration cap. After fitting, check `outcome`: `.maxIterationsReached` means the coefficients are not trustworthy. Perfectly separable classes never converge for `LogisticRegression`.
- Predict with the same fitted scaler that transformed the training data, never with a freshly fitted one. `Pipeline` does this for you: `pipeline.predict(rawFeatures)` scales internally (and applies PCA when the pipeline has a reducer).
- `Pipeline.fit(features:targets:)` with no extra arguments resolves to `Pipeline<LinearRegression>`. To get gradient descent, annotate the type: `let model: Pipeline<GradientDescent> = try Pipeline.fit(...)`.
- `Pipeline` exposes `predict` only. For probabilities from a logistic pipeline, transform first, then call the inner model: `pipeline.model.predictProbabilities(pipeline.scaler.transform(rows))`. If the pipeline has a `reducer`, apply `reducer.transform` after the scaler.
- Fit `PCA` on standardized data, or use `Pipeline.fit(features:labels:componentCount:k:)`, which standardizes first. Read `explainedVarianceRatios` to choose `componentCount`.
- From 1.6.0, `KNearestNeighbors` breaks vote ties toward the nearest neighbor's label. Earlier versions could resolve ties differently from run to run.

## Splitting and randomness

- Every random API takes an explicit `seed: UInt64` (or a `RandomNumberGenerator`). Most have no default seed, so pass one.
- For paired features and labels, use `features.stratifiedSplit(labels:testRatio:seed:)`, which returns `trainFeatures`, `testFeatures`, `trainLabels`, and `testLabels` and keeps class balance. Calling `trainTestSplit(testRatio:seed:)` separately on two equal-length arrays with the same seed also produces aligned splits.
- For cross-validation, `kFoldIndices(k:seed:)` returns index folds; index into both arrays with them.

## Evaluation

- Metrics are methods on the predictions: `predictions.confusionMatrix(actual: testLabels)`, `predictions.classificationReport(actual:)`, `fitted.rSquared(actual:)`, `fitted.rootMeanSquaredError(actual:)`.
- `LinearRegression.summary(features:targets:)` (from 1.2.0) gives standard errors, p-values, and confidence intervals. It throws.

## Names that changed or are often guessed wrong

- `standardDeviation()`, not `std()` (removed in 1.2.0). Since 1.2.0, `standardDeviation()` and `variance()` default to the sample convention, `ddof: 1`; pass `ddof: 0` for the population value.
- `argMin()` and `argMax()` are the current names. `indexOfMinimum` and `indexOfMaximum` do not exist, whatever the 1.1.0 release notes say.
- `quartiles()` returns a `Quartiles` struct (from 1.2.0) with `min`, `q1`, `median`, `q3`, `max`, and `iqr`. There is no `interquartileRange` field.
- `topIndices(k:)` results carry a `rank` field from 1.0.1, so destructure by name, not by position.
- `DistanceMetric` gained cases in 1.6.0 and `MatrixError` gained `.notSymmetric`. Write `switch` statements over Quiver enums with a `default` or `@unknown default` branch. In review, flag a plain `default` that would silently absorb the new metrics.

## Persistence

- Models, scalers, pipelines, and result types are `Codable` and `Equatable`. Save with `JSONEncoder().encode(model)` and load with `JSONDecoder().decode(LinearRegression.self, from: data)`. Do not hand-write coefficient serialization.
- `EmbeddingIndex` is not itself `Codable`, because it holds an embedder. Encode `index.snapshot`, then rebuild with `EmbeddingIndex(snapshot, embedder: embedder)`.

## Retrieval (RAG)

- `Chunker` and `Embedder` are protocols, and Quiver ships no concrete chunker or embedder. Write a small conforming struct. A chunker splits the text and hands the pieces to `asChunks()`, which trims, drops empty pieces, and numbers them. An embedder returns `[Double]?`: `nil` when the text cannot be embedded.
- In an app, an embedder usually wraps Apple's NaturalLanguage framework. Quiver itself has no NaturalLanguage dependency, so the conformer lives in the app.
- Use `EmbeddingIndex<Label>` as the vector store, where `Label` is any `Codable & Equatable` payload the app defines. `retrieve(_:k:)` returns a `RetrievalResult`. Check `isAboveGate(floor:outlierZ:)` before trusting the top hit, so a query the corpus does not cover isn't answered from noise.

## True Effort Score

- Hold `TrueEffortScore` in a `var`; `record`, `pause`, `resume`, `finalize`, and `discardRun` are mutating. `TrueEffortScore()` starts a new runner and does not throw. `TrueEffortScore(history:labeledSamples:labels:)` seeds from saved runs and throws `TESError`.
- Call `record(heartRate:pace:cadence:grade:verticalOscillation:altitude:at:)` once per sensor sample with an absolute `Date`. Quiver derives the time deltas; do not track them yourself. Units: bpm, min/km, steps/min, grade in percent (negative is downhill), vertical oscillation in cm, altitude in meters. Pass `hrTrust:` below `1.0` when the heart-rate reading is doubtful.
- Set `location = .indoor` before the first sample of a treadmill run. Indoor runs are scored but not folded into history.
- `finalize()` returns `nil` when active time (`timerTime`) is under 60 seconds, and the run is discarded. Always unwrap its result.
- On a first run, `baseline`, `TESResult.meanResidual`, and `TESResult.expectedHeartRate` are `nil`. Treat `baseline == nil` as the cold-start state.
- Present `adjusted` together with `meanResidual` and the session terms; do not reduce a run to one number. Quiver has no readiness or recovery-advice API. Readiness is something an app presents from these results, so do not invent a Quiver call for it.
- Persist the runner by encoding the whole `TrueEffortScore` (it is `Codable`) or its `history: [Workout]`. The classifier is frozen after seeding; never refit it on its own predictions.
- `k` must not exceed `TrueEffortScore.anchorSamples.count`.
