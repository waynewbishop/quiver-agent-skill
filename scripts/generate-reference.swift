// generate-reference.swift
//
// Builds the quiver-swift-ml skill's reference files from Quiver's public API.
// For every release tag it dumps the symbol graph (cached under .cache/), then:
//   - renders the newest tag's public API into reference/<topic>.md, grouped by source file,
//   - tags each API with the first release it appeared in,
//   - builds reference/changes.md from the release notes plus a symbol diff between tags,
//   - rewrites the generated blocks in SKILL.md (coverage line, version rules, file list).
//
// Usage:  swift scripts/generate-reference.swift [--quiver <path-to-quiver-repo>]
// The Quiver repo defaults to ../quiver next to this repo. Release notes come from `gh`.

import Foundation

// MARK: - Paths

let fileManager = FileManager.default
let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let skillDir = repoRoot.appendingPathComponent("quiver/skills/quiver-swift-ml")
let referenceDir = skillDir.appendingPathComponent("reference")
let cacheDir = repoRoot.appendingPathComponent(".cache")

var quiverRepo = repoRoot.deletingLastPathComponent().appendingPathComponent("quiver")
if let flag = CommandLine.arguments.firstIndex(of: "--quiver"), flag + 1 < CommandLine.arguments.count {
    quiverRepo = URL(fileURLWithPath: CommandLine.arguments[flag + 1])
}

/// Prints a message to standard error and exits with a failure status.
func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(1)
}

/// Runs a shell command and returns its standard output, failing the script on a non-zero exit.
@discardableResult
func shell(_ command: String, in directory: URL? = nil) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = ["-c", command]
    if let directory { process.currentDirectoryURL = directory }
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.standardError
    do { try process.run() } catch { fail("could not run: \(command)") }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { fail("command failed (\(process.terminationStatus)): \(command)") }
    return String(decoding: data, as: UTF8.self)
}

// MARK: - Topics

/// One generated reference file and the source files whose public API it holds.
struct Topic {
    let file: String
    let title: String
    let summary: String
    let sources: [String]
}

// Source files are matched by base name. A public symbol in a file not listed here stops the script.
let topics: [Topic] = [
    Topic(file: "statistics", title: "Statistics", summary: "descriptive statistics, quartiles, skewness, empirical rule, frequency tables",
          sources: ["ArrayStatistics", "Quartiles", "ColumnSummary", "SkewnessReport", "SkewnessAgreement", "EmpiricalRule", "Frequency"]),
    Topic(file: "sampling", title: "Sampling and splitting", summary: "train/test split, k-fold, resampling, bootstrap, sampling distributions",
          sources: ["ArraySampling"]),
    Topic(file: "charts", title: "Chart helpers", summary: "data shaping for Swift Charts: histograms, bins, aggregation, cumulative and stacked series",
          sources: ["ArrayCharts", "AggregationMethod", "BinRule"]),
    Topic(file: "data", title: "Tabular data", summary: "`Panel`, panel summaries, contingency tables",
          sources: ["Panel", "PanelSummary", "ContingencyTable"]),
    Topic(file: "vectors", title: "Vectors and matrices", summary: "dot products, norms, distances, similarity, matrix operations, angles, boolean masks, shape and info",
          sources: ["Quiver", "VectorOperations", "ArrayAngles", "ArrayBoolean", "ArrayInfo", "ArrayReshape"]),
    Topic(file: "elementwise", title: "Element-wise math", summary: "vector arithmetic, scalar broadcasting, element-wise functions",
          sources: ["ArrayArithmetic", "ArrayBroadcast", "ArrayElementwise"]),
    Topic(file: "linear-algebra", title: "Linear algebra", summary: "matrix solve, LU, determinants, eigendecomposition, covariance, matrix and vector rendering",
          sources: ["MatrixSolve", "LUDecomposition", "LogDeterminant", "EigenDecomposition", "CovarianceMatrix", "MatrixError", "MatrixExpression", "ArrayExpression", "VectorForm", "UnicodeMath", "Fraction"]),
    Topic(file: "regression", title: "Regression models", summary: "`LinearRegression`, `Ridge`, `GradientDescent`, `ResidualModel`, coefficients, regression inference (`RegressionSummary`)",
          sources: ["Regressor", "LinearRegression", "Ridge", "GradientDescent", "GradientDescentError", "ResidualModel", "Coefficients", "RegressionSummary"]),
    Topic(file: "classification", title: "Classification models", summary: "`LogisticRegression`, `KNearestNeighbors`, `GaussianNaiveBayes`, distance metrics, and every evaluation metric on predictions (accuracy, confusion matrix, classification report, R², MSE, RMSE)",
          sources: ["Classifier", "LogisticRegression", "KNearestNeighbors", "VoteWeight", "DistanceMetric", "GaussianNaiveBayes", "Classification", "ArrayMetrics", "_VectorMetrics", "ClassificationReport"]),
    Topic(file: "preprocessing-clustering", title: "Preprocessing, clustering, and PCA", summary: "`Pipeline`, `StandardScaler`, `FeatureScaler`, `KMeans`, `PCA`",
          sources: ["Transformer", "Pipeline", "StandardScaler", "FeatureScaler", "KMeansClustering", "Cluster", "PCA"]),
    Topic(file: "tes", title: "True Effort Score", summary: "`TrueEffortScore`: setup, the live recording loop, live readings, `finalize()`",
          sources: ["TrueEffortScore", "Anchors", "WalkingGate", "TESError", "WorkoutLocation"]),
    Topic(file: "tes-results", title: "True Effort Score results", summary: "`TESResult`, `TESBaseline`, `EffortClass`, `EffortSignals`, `Workout`",
          sources: ["TESResult", "TESBaseline", "EffortClass", "EffortSignals", "Workout"]),
    Topic(file: "rag", title: "Embeddings and retrieval", summary: "`Chunker`, `Embedder`, `EmbeddingIndex`, nearest-neighbor lookup, text tokenization",
          sources: ["Chunker", "Embedder", "EmbeddingIndex", "DictionaryNearest", "StringExtensions"]),
    Topic(file: "signal-calculus", title: "Signals and calculus", summary: "Fourier transform, power spectrum, integration and derivatives, numerical Jacobian",
          sources: ["ArrayFourier", "PowerSpectrum", "ArrayIntegration", "Jacobian"]),
    Topic(file: "distributions", title: "Distributions and Bayes", summary: "probability distributions and Bayesian updating",
          sources: ["Distributions", "Bayes"]),
    Topic(file: "generation", title: "Array generation", summary: "array generation, seeded random numbers, random distributions",
          sources: ["ArrayGeneration", "ArrayRandom", "SeededRandomNumberGenerator"]),
    Topic(file: "polynomial", title: "Polynomials", summary: "`Polynomial` and polynomial fitting",
          sources: ["Polynomial", "Polyfit"]),
]

// Members every type carries that add nothing to the reference.
let boilerplateTitles: Set<String> = ["description", "debugDescription", "hash(into:)", "hashValue", "encode(to:)", "init(from:)", "==(_:_:)", "!=(_:_:)", "localizedDescription"]

// Above this estimate a reference file should be split.
let tokenBudget = 4_000

// MARK: - Symbol graph model

struct SymbolGraph: Decodable {
    struct Relationship: Decodable { let kind: String; let source: String; let target: String; let targetFallback: String? }
    let symbols: [Symbol]
    let relationships: [Relationship]?
}

// Conformances worth showing a reader; the rest (Sendable, CustomStringConvertible, …) add noise.
let shownConformances: Set<String> = ["Codable", "Equatable", "Hashable", "Comparable", "Sequence", "Collection", "CaseIterable", "Error",
                                     "Regressor", "Classifier", "Transformer", "Chunker", "Embedder", "RandomNumberGenerator"]

struct Symbol: Decodable {
    struct Kind: Decodable { let identifier: String }
    struct Identifier: Decodable { let precise: String }
    struct Names: Decodable { let title: String }
    struct Line: Decodable { let text: String }
    struct DocComment: Decodable { let uri: String?; let lines: [Line] }
    struct Fragment: Decodable { let spelling: String }
    struct Constraint: Decodable { let kind: String; let lhs: String; let rhs: String }
    struct Generics: Decodable { let constraints: [Constraint]? }
    struct Extension: Decodable { let extendedModule: String; let constraints: [Constraint]? }
    struct Position: Decodable { let line: Int }
    struct Location: Decodable { let uri: String; let position: Position }

    let kind: Kind
    let identifier: Identifier
    let pathComponents: [String]
    let names: Names
    let docComment: DocComment?
    let declarationFragments: [Fragment]?
    let swiftGenerics: Generics?
    let swiftExtension: Extension?
    let location: Location?
}

/// A public API in one release, flattened for rendering and diffing.
struct API {
    let kind: String
    let owner: String
    let name: String
    let title: String
    let declaration: String
    let constraint: String
    let doc: [String]
    let file: String?
    let line: Int
    var conformances: [String] = []

    /// Identity across releases: owner, name, and extension constraint.
    var key: String { "\(owner)|\(title)|\(constraint)" }
    var display: String { owner.isEmpty ? name : "\(owner).\(name)" }
    var isType: Bool { ["swift.struct", "swift.enum", "swift.protocol", "swift.class", "swift.typealias"].contains(kind) }
}

/// Describes an extension's generic constraints in the form a reader writes them, such as `[Double]`.
func constraintText(_ constraints: [Symbol.Constraint]?) -> String {
    guard let constraints, !constraints.isEmpty else { return "" }
    let parts = constraints.map { c -> String in
        if c.lhs == "Element", c.kind == "sameType" { return "Element == \(c.rhs)" }
        return c.kind == "sameType" ? "\(c.lhs) == \(c.rhs)" : "\(c.lhs): \(c.rhs)"
    }
    return parts.sorted().joined(separator: ", ")
}

/// Loads both symbol graph files for one release and flattens them into APIs.
func loadAPIs(_ directory: URL) -> [API] {
    var apis: [API] = []
    for name in ["Quiver.symbols.json", "Quiver@Swift.symbols.json"] {
        let url = directory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else { continue }
        guard let graph = try? JSONDecoder().decode(SymbolGraph.self, from: data) else { fail("could not decode \(url.path)") }
        var conforms: [String: Set<String>] = [:]
        for relation in graph.relationships ?? [] where relation.kind == "conformsTo" {
            let name = relation.targetFallback.map { String($0.split(separator: ".").last ?? Substring($0)) }
                ?? graph.symbols.first { $0.identifier.precise == relation.target }?.names.title ?? ""
            conforms[relation.source, default: []].insert(name)
        }
        for symbol in graph.symbols {
            if symbol.identifier.precise.contains("::SYNTHESIZED::") { continue }
            if symbol.kind.identifier == "swift.extension" { continue }
            if boilerplateTitles.contains(symbol.names.title) { continue }
            let owner = symbol.pathComponents.dropLast().joined(separator: ".")
            let declaration = (symbol.declarationFragments ?? []).map(\.spelling).joined()
            let constraint = constraintText(symbol.swiftExtension?.constraints ?? symbol.swiftGenerics?.constraints)
            let uri = symbol.location?.uri ?? symbol.docComment?.uri
            let file = uri.map { URL(string: $0)?.deletingPathExtension().lastPathComponent ?? $0 }
            var found = conforms[symbol.identifier.precise] ?? []
            if found.contains("Encodable") && found.contains("Decodable") { found.insert("Codable") }
            apis.append(API(kind: symbol.kind.identifier, owner: owner, name: symbol.pathComponents.last ?? symbol.names.title, title: symbol.names.title,
                            declaration: declaration, constraint: symbol.swiftExtension == nil ? "" : constraint,
                            doc: symbol.docComment?.lines.map(\.text) ?? [], file: file,
                            line: symbol.location?.position.line ?? 0,
                            conformances: found.filter { shownConformances.contains($0) }.sorted()))
        }
    }
    return apis
}

// MARK: - Releases and cache

/// Returns the release tags at 1.0.0 or later, oldest first.
func releaseTags() -> [String] {
    let tags = shell("git -C '\(quiverRepo.path)' tag --list").split(separator: "\n").map(String.init)
    let releases = tags.filter { $0.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil }
    let parsed = releases.map { tag in (tag, tag.split(separator: ".").compactMap { Int($0) }) }
    return parsed.filter { $0.1[0] >= 1 }.sorted { $0.1.lexicographicallyPrecedes($1.1) }.map(\.0)
}

/// Returns the cached symbol graph directory for a tag, building it from the tagged source if needed.
func symbolGraphs(for tag: String) -> URL {
    let target = cacheDir.appendingPathComponent("symbols/\(tag)")
    if fileManager.fileExists(atPath: target.appendingPathComponent("Quiver.symbols.json").path) { return target }
    print("Building symbol graph for \(tag)…")
    let source = cacheDir.appendingPathComponent("src/\(tag)")
    try? fileManager.removeItem(at: source)
    try? fileManager.createDirectory(at: source, withIntermediateDirectories: true)
    shell("git -C '\(quiverRepo.path)' archive '\(tag)' | tar -x -C '\(source.path)'")
    shell("swift package dump-symbol-graph --minimum-access-level public > /dev/null", in: source)
    let found = shell("find .build -name 'Quiver.symbols.json' -path '*symbolgraph*' | head -1", in: source)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !found.isEmpty else { fail("no symbol graph produced for \(tag)") }
    let produced = source.appendingPathComponent(found).deletingLastPathComponent()
    try? fileManager.createDirectory(at: target, withIntermediateDirectories: true)
    for name in ["Quiver.symbols.json", "Quiver@Swift.symbols.json"] {
        let from = produced.appendingPathComponent(name)
        if fileManager.fileExists(atPath: from.path) {
            try? fileManager.copyItem(at: from, to: target.appendingPathComponent(name))
        }
    }
    try? fileManager.removeItem(at: source)
    return target
}

/// Returns a tag's release notes from GitHub, cached after the first fetch.
func releaseNotes(for tag: String) -> String {
    let cached = cacheDir.appendingPathComponent("notes/\(tag).md")
    if let text = try? String(contentsOf: cached, encoding: .utf8) { return normalizedLineEndings(text) }
    let text = shell("gh release view '\(tag)' -R waynewbishop/quiver --json body -q .body")
    try? fileManager.createDirectory(at: cached.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? text.write(to: cached, atomically: true, encoding: .utf8)
    return normalizedLineEndings(text)
}

/// Converts CRLF and lone CR line endings to LF.
func normalizedLineEndings(_ text: String) -> String {
    text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
}

// MARK: - Doc comment summaries

/// Rewrites DocC symbol links such as ``Swift/Array/mean()`` as plain code spans.
func plainLinks(_ text: String) -> String {
    var result = text
    while let range = result.range(of: #"``[^`]+``"#, options: .regularExpression) {
        let inner = result[range].dropFirst(2).dropLast(2)
        let last = inner.split(separator: "/").last.map(String.init) ?? String(inner)
        result.replaceSubrange(range, with: "`\(last)`")
    }
    return result
}

/// Returns a doc comment's first paragraph plus its Returns and Throws notes.
func summary(_ lines: [String]) -> String {
    var paragraph: [String] = []
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { if paragraph.isEmpty { continue } else { break } }
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("```") { break }
        paragraph.append(trimmed)
    }
    var parts = [paragraph.joined(separator: " ")]
    for label in ["Returns", "Throws"] {
        var note: [String] = []
        var capturing = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- \(label):") {
                capturing = true
                note.append(String(trimmed.dropFirst(label.count + 3)).trimmingCharacters(in: .whitespaces))
            } else if capturing {
                if trimmed.isEmpty || trimmed.hasPrefix("- ") { break }
                note.append(trimmed)
            }
        }
        if !note.isEmpty { parts.append("\(label): \(note.joined(separator: " "))") }
    }
    return plainLinks(parts.filter { !$0.isEmpty }.joined(separator: " "))
}

// MARK: - Version helpers

/// Compares two dotted version strings numerically.
func versionLess(_ a: String, _ b: String) -> Bool {
    let x = a.split(separator: ".").compactMap { Int($0) }
    let y = b.split(separator: ".").compactMap { Int($0) }
    return x.lexicographicallyPrecedes(y)
}

// MARK: - Main

let tags = releaseTags()
guard let latest = tags.last else { fail("no release tags found in \(quiverRepo.path)") }
let first = tags[0]

var releases: [(tag: String, apis: [API])] = []
for tag in tags { releases.append((tag, loadAPIs(symbolGraphs(for: tag)))) }

// The first release in which each API key appears.
var since: [String: String] = [:]
for release in releases {
    for api in release.apis where since[api.key] == nil { since[api.key] = release.tag }
}

let current = releases.last!.apis
let sourceToTopic = Dictionary(uniqueKeysWithValues: topics.flatMap { t in t.sources.map { ($0, t.file) } })

// Types keep their own file; members without a location fall back to their owner's file.
let typeFiles = Dictionary(current.filter(\.isType).compactMap { api in api.file.map { (api.display, $0) } }, uniquingKeysWith: { a, _ in a })

var byTopic: [String: [API]] = [:]
var unmapped: Set<String> = []
for api in current {
    guard let file = api.file ?? typeFiles[api.owner] else { continue }
    guard let topic = sourceToTopic[file] else { unmapped.insert(file); continue }
    byTopic[topic, default: []].append(api)
}
if !unmapped.isEmpty {
    fail("public API in source files with no topic mapping: \(unmapped.sorted().joined(separator: ", ")). Add them to `topics`.")
}

/// Renders one API as a bullet: declaration, summary, and since tag.
func bullet(_ api: API) -> String {
    var text = "- `\(api.declaration)`"
    let note = summary(api.doc)
    if !note.isEmpty { text += " — \(note)" }
    if let version = since[api.key], version != first { text += " *(since \(version))*" }
    return text
}

/// Renders one topic file from its APIs, grouped under each owning type or extension.
func render(_ topic: Topic, _ apis: [API]) -> String {
    let fileOrder = Dictionary(uniqueKeysWithValues: topic.sources.enumerated().map { ($1, $0) })
    let sorted = apis.sorted { a, b in
        let fa = fileOrder[a.file ?? typeFiles[a.owner] ?? ""] ?? 0
        let fb = fileOrder[b.file ?? typeFiles[b.owner] ?? ""] ?? 0
        return fa != fb ? fa < fb : a.line < b.line
    }
    var groups: [(heading: String, intro: String, items: [String])] = []
    var index: [String: Int] = [:]
    for api in sorted {
        let heading: String
        var intro = ""
        if api.isType {
            heading = api.display
            intro = "`\(api.declaration)` — \(summary(api.doc))"
            if let version = since[api.key], version != first { intro += " *(since \(version))*" }
            if !api.conformances.isEmpty { intro += "\n\nConforms to: " + api.conformances.joined(separator: ", ") + "." }
        } else if ["Array", "Sequence", "Collection", "String", "Dictionary", "Double", "Int", "Float", "BinaryFloatingPoint", "FloatingPoint", "Numeric"].contains(api.owner) {
            heading = api.constraint.isEmpty ? "\(api.owner) extensions" : "\(api.owner) extensions where \(api.constraint)"
        } else {
            heading = api.owner
        }
        if let position = index[heading] {
            if api.isType { groups[position].intro = intro } else { groups[position].items.append(bullet(api)) }
        } else {
            index[heading] = groups.count
            groups.append((heading, intro, api.isType ? [] : [bullet(api)]))
        }
    }
    var out = "# \(topic.title)\n\n"
    out += "<!-- Generated by scripts/generate-reference.swift from the Quiver \(latest) public API. Do not edit by hand. -->\n\n"
    out += "Every API below exists in Quiver \(first) and later unless it is tagged *(since X)*. Each entry is the declaration, then the first line of its documentation.\n"
    for group in groups {
        out += "\n## \(group.heading)\n\n"
        if !group.intro.isEmpty { out += "\(group.intro)\n\n" }
        if !group.items.isEmpty { out += group.items.joined(separator: "\n") + "\n" }
    }
    return out
}

try? fileManager.createDirectory(at: referenceDir, withIntermediateDirectories: true)
var sizes: [(String, Int)] = []

/// Writes a generated file and records its approximate token count.
func write(_ text: String, _ name: String) {
    let url = referenceDir.appendingPathComponent("\(name).md")
    do { try text.write(to: url, atomically: true, encoding: .utf8) } catch { fail("could not write \(url.path)") }
    sizes.append((name, text.utf8.count / 4))
}

for topic in topics {
    write(render(topic, byTopic[topic.file] ?? []), topic.file)
}

// MARK: - changes.md

/// Extracts the sections of a release note that describe breaking or behavior changes.
func changeSections(_ notes: String) -> String {
    var out: [String] = []
    var capturing = false
    var compatibility = ""
    for line in notes.components(separatedBy: "\n") {
        if line.hasPrefix("**Compatibility:**") {
            compatibility = String(line.dropFirst("**Compatibility:**".count)).trimmingCharacters(in: .whitespaces)
            continue
        }
        if line.hasPrefix("#") {
            let heading = line.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
            let wanted = heading.range(of: #"^(Breaking|Changed?\b|Upgrade notes)"#, options: .regularExpression) != nil
            let docsOnly = heading.range(of: #"(?i)docc|catalog|documentation"#, options: .regularExpression) != nil
            capturing = wanted && !docsOnly
            if capturing { out.append("### \(heading)") }
            continue
        }
        if capturing && line.trimmingCharacters(in: .whitespaces) != "---" { out.append(line) }
    }
    var text = out.joined(separator: "\n")
    text = text.replacingOccurrences(of: #"\[([^\]]+)\]\(https?://[^)]+\)"#, with: "$1", options: .regularExpression)
    text = text.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
    if !compatibility.isEmpty { text = "Compatibility: \(compatibility)\n\n" + text }
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Reads the hand-maintained corrections to published release notes, keyed by version.
func releaseNoteCorrections() -> [String: String] {
    let url = repoRoot.appendingPathComponent("scripts/release-notes-corrections.md")
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
    var result: [String: String] = [:]
    var version: String?
    for line in text.components(separatedBy: "\n") {
        if line.hasPrefix("## ") { version = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces); continue }
        if let version, !line.hasPrefix("# ") { result[version, default: ""] += line + "\n" }
    }
    return result.mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.value.isEmpty }
}

let corrections = releaseNoteCorrections()

var changes = "# Changes by release\n\n"
changes += "<!-- Generated by scripts/generate-reference.swift from Quiver's release notes and a public-API diff between tags. Do not edit by hand. -->\n\n"
changes += "Read the sections between the project's resolved Quiver version and the version being targeted. Release-note text explains renames and behavior changes; the API diff lists every public symbol removed or re-signatured, including ones the notes do not mention.\n"

for position in 1..<releases.count {
    let previous = releases[position - 1]
    let release = releases[position]
    var section = "\n## \(release.tag)\n\n"
    if let correction = corrections[release.tag] {
        section += "> **Read this first. The release notes below are wrong in places.** \(correction)\n\n"
    }
    let notes = changeSections(releaseNotes(for: release.tag))
    section += notes.isEmpty ? "The release notes list no breaking or behavior changes.\n" : notes + "\n"

    let oldByKey = Dictionary(previous.apis.map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
    let newByKey = Dictionary(release.apis.map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
    let newNames = Set(release.apis.map { "\($0.owner)|\($0.title)" })

    var removed: [String] = []
    var resigned: [String] = []
    for (key, old) in oldByKey.sorted(by: { $0.key < $1.key }) {
        if let new = newByKey[key] {
            if new.declaration != old.declaration && !old.isType {
                resigned.append("- `\(old.display)`: `\(old.declaration)` → `\(new.declaration)`")
            }
        } else if newNames.contains("\(old.owner)|\(old.title)") {
            resigned.append("- `\(old.display)`: constraint changed from `\(old.constraint.isEmpty ? "none" : old.constraint)`")
        } else {
            removed.append("- `\(old.display)`" + (old.constraint.isEmpty ? "" : " (where \(old.constraint))"))
        }
    }

    let oldEnums = Set(previous.apis.filter { $0.kind == "swift.enum" }.map(\.display))
    let oldCases = Set(previous.apis.filter { $0.kind == "swift.enum.case" }.map(\.key))
    var newCases: [String: [String]] = [:]
    for api in release.apis where api.kind == "swift.enum.case" && oldEnums.contains(api.owner) && !oldCases.contains(api.key) {
        newCases[api.owner, default: []].append("`.\(api.name)`")
    }

    if !removed.isEmpty || !resigned.isEmpty || !newCases.isEmpty {
        section += "\n### API diff from \(previous.tag)\n"
        if !removed.isEmpty { section += "\nRemoved or renamed (calls to these no longer compile):\n\n" + removed.joined(separator: "\n") + "\n" }
        if !resigned.isEmpty { section += "\nSignature changed:\n\n" + resigned.joined(separator: "\n") + "\n" }
        for (owner, cases) in newCases.sorted(by: { $0.key < $1.key }) {
            section += "\nNew cases on `\(owner)`: \(cases.sorted().joined(separator: ", ")). A `switch` over `\(owner)` with no `default` stops compiling. A plain `default` compiles but silently routes the new cases into it, so flag it in review.\n"
        }
    }
    changes += section
}
write(changes, "changes")

// MARK: - SKILL.md generated blocks

/// Replaces the text between a named pair of generated-block markers.
func replaceBlock(_ name: String, in text: String, with body: String) -> String {
    let begin = "<!-- BEGIN GENERATED: \(name) -->"
    let end = "<!-- END GENERATED: \(name) -->"
    guard let start = text.range(of: begin), let stop = text.range(of: end, range: start.upperBound..<text.endIndex) else {
        fail("SKILL.md is missing the \(name) markers")
    }
    return text.replacingCharacters(in: start.upperBound..<stop.lowerBound, with: "\n\(body)\n")
}

let skillURL = skillDir.appendingPathComponent("SKILL.md")
guard var skill = try? String(contentsOf: skillURL, encoding: .utf8) else { fail("could not read SKILL.md") }
skill = skill.replacingOccurrences(of: #"quiver-coverage: "[^"]*""#, with: "quiver-coverage: \"\(latest)\"", options: .regularExpression)
skill = replaceBlock("version", in: skill, with: """
This skill covers Quiver \(first) through \(latest). Before writing or reviewing code, read the project's `Package.resolved` (or the Quiver requirement in `Package.swift`) and find the Quiver version.

- Use only APIs available in that version. Reference entries tagged *(since X)* need Quiver X or later.
- If the project resolves a Quiver newer than \(latest), tell the user this skill covers Quiver through \(latest) and suggest updating the plugin. Treat any API not in the reference files as unknown rather than guessing.
- If no project is visible, assume Quiver \(latest) and say so, or ask which version the user is on.
""")
skill = replaceBlock("install", in: skill, with: """
Add Quiver only when the user asks for it, or asks for Quiver code in a project that doesn't have it yet. Confirm before editing `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/waynewbishop/quiver", from: "\(latest)")
],
targets: [
    .target(name: "App", dependencies: [.product(name: "Quiver", package: "quiver")])
]
```

In an Xcode app project, add the same URL with File > Add Package Dependencies.
""")
let fileList = (["- `reference/changes.md`: breaking changes, behavior changes, and API diffs by release"]
    + topics.map { "- `reference/\($0.file).md`: \($0.summary)" }).joined(separator: "\n")
skill = replaceBlock("reference-files", in: skill, with: fileList)
do { try skill.write(to: skillURL, atomically: true, encoding: .utf8) } catch { fail("could not write SKILL.md") }

// MARK: - Report

print("Generated reference for Quiver \(latest) (\(current.count) public APIs across \(tags.count) releases).")
var overBudget = false
for (name, tokens) in sizes {
    let flag = tokens > tokenBudget ? "  ← over the \(tokenBudget)-token budget; split this topic" : ""
    if tokens > tokenBudget { overBudget = true }
    print(String(format: "  %-18@ ~%5d tokens%@", name as NSString, tokens, flag as NSString))
}
if overBudget { exit(2) }
