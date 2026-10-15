# Quiver cookbook

Hand-written. Each recipe compiles and runs against Quiver 1.6.0 as top-level code, such as the `main.swift` of an executable target or a playground page, and the output comments come from an actual run. Inside a function or method, the same code works unchanged. Adapt the data; keep the shape of the calls.

## Descriptive statistics

```swift
import Quiver

let times = [12.1, 11.8, 12.6, 13.0, 11.9, 12.4]

// Every statistic that can be undefined returns an optional.
if let mean = times.mean(),
   let spread = times.standardDeviation(),   // sample convention, ddof: 1
   let q = times.quartiles() {
    print(mean)       // ≈ 12.3
    print(spread)     // ≈ 0.456
    print(q.median)   // 12.25
    print(q.iqr)      // ≈ 0.6
}

let heights = [150.0, 160.0, 170.0, 180.0]
let weights = [50.0, 58.0, 69.0, 80.0]
if let r = heights.correlation(with: weights) {
    print(r)      // ≈ 0.997
}
// A constant vector has no correlation: [1.0, 1.0, 1.0].correlation(with: …) is nil.
```

## Classifier with a train/test split

```swift
import Quiver

let features: [[Double]] = [
    [1.0, 200.0], [1.2, 210.0], [0.9, 190.0], [1.1, 205.0], [1.3, 215.0],
    [3.0, 600.0], [3.2, 620.0], [2.9, 590.0], [3.1, 610.0], [3.3, 630.0],
]
let labels = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]

// Split features and labels together, keeping class balance.
let split = features.stratifiedSplit(labels: labels, testRatio: 0.4, seed: 42)

// Pipeline standardizes the columns, so the second feature's scale does not swamp the first.
let model = Pipeline.fit(features: split.trainFeatures, labels: split.trainLabels, k: 3)

let predictions = model.predict(split.testFeatures)
let matrix = predictions.confusionMatrix(actual: split.testLabels)
print(matrix.accuracy)                     // 1.0

// Raw query rows go straight in; the pipeline scales them with the training scaler.
print(model.predict([[1.05, 202.0]]))      // [0]
```

## Logistic regression with probabilities

```swift
import Quiver

let hours: [[Double]] = [[1.0], [2.0], [3.0], [4.0], [5.0], [6.0], [7.0], [8.0]]
let passed = [0, 0, 0, 1, 0, 1, 1, 1]

do {
    let model = try Pipeline.fit(features: hours, labels: passed,
                                 learningRate: 0.1, maxIterations: 5000)

    // An iterative model is only trustworthy once it converges.
    if model.model.outcome == .converged {
        print(model.predict([[2.5], [6.5]]))   // [0, 1]

        // Pipeline has no predictProbabilities; scale with its own scaler, then ask the model.
        let scaled = model.scaler.transform([[4.5]])
        print(model.model.predictProbabilities(scaled))   // [0.5]
    } else {
        print("Not converged; raise maxIterations or learningRate")
    }
} catch {
    print("Training diverged: \(error)")
}
```

## Linear regression

```swift
import Quiver

let size: [Double] = [50, 70, 90, 110, 130]
let price: [Double] = [150, 200, 250, 300, 350]

do {
    let model = try LinearRegression.fit(features: size, targets: price)
    print(model.equation())            // y = 25.00 + 2.50x
    print(model.predict([100.0]))      // [275.0]

    let fitted = model.predict(size)
    print(fitted.rSquared(actual: price))   // 1.0
} catch {
    print("The features are linearly dependent: \(error)")
}
```

To use gradient descent through a pipeline, annotate the type. Without the annotation, `Pipeline.fit(features:targets:)` builds a `Pipeline<LinearRegression>`:

```swift
let rows: [[Double]] = [[50], [70], [90], [110], [130]]
let descent: Pipeline<GradientDescent> = try Pipeline.fit(
    features: rows, targets: price, learningRate: 0.1, maxIterations: 5000)
print(descent.predict([[100.0]]))   // ≈ [275.0]
```

## Principal component analysis

```swift
import Quiver

let data: [[Double]] = [
    [2.5, 2.4, 0.5], [0.5, 0.7, 1.9], [2.2, 2.9, 0.6], [1.9, 2.2, 0.8],
    [3.1, 3.0, 0.3], [2.3, 2.7, 0.7], [2.0, 1.6, 1.0], [1.0, 1.1, 1.6],
]

// Standardize first; PCA on raw columns is dominated by the largest-scale column.
let scaler = StandardScaler.fit(features: data)
let scaled = scaler.transform(data)

let pca = PCA.fit(features: scaled, componentCount: 2)
print(pca.explainedVarianceRatios)   // ≈ [0.968, 0.028]

let reduced = pca.transform(scaled)  // 8 rows × 2 columns

// Or scale, reduce, and classify in one model.
let labels = [1, 0, 1, 1, 1, 1, 0, 0]
let model = Pipeline.fit(features: data, labels: labels, componentCount: 2, k: 3)
print(model.predict([[2.4, 2.5, 0.6]]))   // [1]
```

## K-means clustering

```swift
import Quiver

let points: [[Double]] = [[1, 1], [1.2, 0.8], [0.9, 1.1], [8, 8], [8.2, 7.9], [7.8, 8.1]]

// A seed makes the clustering reproducible. Cluster numbers are arbitrary.
let model = KMeans.fit(data: points, k: 2, seed: 42)
print(model.labels)                          // one cluster number per point
print(model.predict([[1.0, 0.9], [8.1, 8.0]]))   // two different cluster numbers
```

## Retrieval for a language model (RAG)

```swift
import Foundation
import Quiver

// Splits a document on blank lines.
struct ParagraphChunker: Chunker {
    func chunk(_ text: String) -> [Chunk] {
        text.components(separatedBy: "\n\n").asChunks()
    }
}

// Averages the vectors of the words a lookup table recognizes. In an app, wrap NaturalLanguage instead.
struct TableEmbedder: Embedder {
    let table: [String: [Double]]

    func embed(_ text: String) -> [Double]? {
        text.tokenize().embed(using: table).meanVector()
    }
}

// The app's own payload: which document and which fragment.
struct SourcedChunk: Codable, Equatable {
    let chunk: Chunk
    let sourceID: String
}

let table: [String: [Double]] = [
    "rise": [0.95, 0.10, 0.10], "slow": [0.80, 0.20, 0.15], "long": [0.75, 0.15, 0.20],
    "knead": [0.15, 0.85, 0.20], "dough": [0.20, 0.90, 0.25], "smooth": [0.10, 0.80, 0.30],
]
let embedder = TableEmbedder(table: table)
let document = "Let the dough rise slowly.\n\nKnead the dough until smooth."

var index = EmbeddingIndex<SourcedChunk>(embedder: embedder)
for chunk in document.chunked(using: ParagraphChunker()) {
    index.add(chunk.text, label: SourcedChunk(chunk: chunk, sourceID: "bread"))
}

let result = index.retrieve("how long should it rise", k: 1)

// Only answer from the corpus when the top hit clears the gate.
if result.isAboveGate(floor: 0.30, outlierZ: 3.0), let top = result.hits.first {
    print(top.label.chunk.text)   // Let the dough rise slowly.
}

// Persist the snapshot, not the index; the embedder is supplied again on load.
do {
    let data = try JSONEncoder().encode(index.snapshot)
    let snapshot = try JSONDecoder().decode(EmbeddingIndex<SourcedChunk>.Snapshot.self, from: data)
    let restored = EmbeddingIndex(snapshot, embedder: embedder)
    print(restored.count)   // 2
} catch {
    print("Could not save the index: \(error)")
}
```

## True Effort Score workout session

```swift
import Foundation
import Quiver

var tes = TrueEffortScore()   // a new runner; does not throw
let sampleDate = Date()       // in an app, the timestamp of each HealthKit sample

// Indoor runs must say so before the first sample: tes.location = .indoor

// Once per sensor sample: bpm, min/km, steps/min, grade %, cm, meters, absolute time.
tes.record(heartRate: 150, pace: 5.5, cadence: 172, grade: 0.5,
           verticalOscillation: 8.0, altitude: 100, at: sampleDate)

// Live readings for the UI; each is nil until it has data.
let effort = tes.currentEffort        // e.g. .tempo
let gap = tes.currentResidual         // nil until a personal baseline exists

// Closing the run returns nil under 60 seconds of active time.
if let run = tes.finalize() {
    print(run.adjusted)               // the headline score
    print(run.meanResidual as Any)    // nil on a first run
    print(tes.sessionCount)           // 1
}

// The whole model is Codable; persist it between runs.
do {
    let saved = try JSONEncoder().encode(tes)
    let restored = try JSONDecoder().decode(TrueEffortScore.self, from: saved)
    print(restored == tes)   // true
} catch {
    print("Could not save the runner: \(error)")
}
```

## Saving and loading a model

```swift
import Foundation
import Quiver

do {
    let model = try LinearRegression.fit(features: [1.0, 2.0, 3.0], targets: [2.0, 4.0, 6.0])
    let data = try JSONEncoder().encode(model)
    let loaded = try JSONDecoder().decode(LinearRegression.self, from: data)
    print(loaded == model)   // true
} catch {
    print("Could not save the model: \(error)")
}
```
