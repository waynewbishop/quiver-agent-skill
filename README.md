# Quiver Agent Skill

A Claude Code skill that provides compiler-verified API signatures, conventions, and migration rules for projects using [Quiver](https://github.com/waynewbishop/quiver).

<p>
    <img src="https://img.shields.io/badge/Quiver-1.0.0–1.6.0-2980b9.svg" alt="Covers Quiver 1.0.0 through 1.6.0." />
    <img src="https://img.shields.io/badge/swift-5.9+-8e44ad.svg" alt="Requires Swift 5.9 or later." />
    <img src="https://img.shields.io/badge/license-Apache%202.0-95a5a6.svg" alt="Apache 2.0 license." />
</p>

## Overview

The Quiver Agent Skill equips Claude Code with a verified reference of Quiver’s public API across releases 1.0.0 through 1.6.0. 

Quiver is a pure Swift framework for statistics, linear algebra, and machine learning. It extends the standard Array type, so every operation reads as ordinary Swift code. With zero external dependencies, it covers the entire data workflow including analysis, transformation, and modeling in readable code that runs identically on iOS, macOS, watchOS, tvOS, visionOS, and the server.

By anchoring Claude to the project’s resolved Quiver version, the skill ensures generated code adheres to Quiver’s exact type signatures, safe optional handling, and architectural conventions from the first prompt.

### Who is the Skill for

- **Students:** Working through a course, textbook, or self-study. The skill gives students an AI assistant that writes correct Quiver code on the first attempt, letting them focus on mathematical concepts rather than debugging invalid syntax.
- **Educators:** Preparing lectures, problem sets, and course modules across applied linear algebra, descriptive statistics, regression, and clustering. The skill ensures generated examples and starter code align with Quiver's canonical API.
- **Apple-platform developers:** Prototyping models or integrating numerical computing into iOS, macOS, watchOS, or visionOS apps. The skill accelerates implementation with verified API signatures, safe optional handling, and upgrade audits across releases.

## Why Use the Skill

### 1. Accurate API signatures and labels
Claude looks up exact signatures before writing, eliminating common hallucinations:
- Uses current symbol names rather than deprecated ones (e.g., `standardDeviation()` instead of `std()`, `argMax()` instead of `indexOfMaximum`).
- Supplies mandatory parameters like `seed: UInt64` for reproducible operations.
- Distinguishes classification labels (`labels: [Int]`) from regression targets (`targets: [Double]`).

### 2. Preventing silent logic bugs
Because Quiver builds directly on Swift's standard `Array`, general models easily confuse language behavior with framework operations:
- **Vector math:** In Swift, `a + b` concatenates two arrays. The skill ensures Claude calls `a.add(b)` or `a.subtract(b)` for element-wise arithmetic.
- **Optional safety:** Statistics that can be undefined (`mean()`, `correlation(with:)`) return optionals. The skill prevents Claude from inserting force-unwraps (`!`) that crash on empty data.
- **Model convergence:** Iterative algorithms (`LogisticRegression`, `GradientDescent`) depend on feature scale. The skill instructs Claude to wrap them in `Pipeline` with `StandardScaler` and check `outcome.converged`.

### 3. Version-aware reviews and upgrades
When we ask Claude to review an existing project or prepare for an upgrade, the skill reads `Package.resolved` to determine the project's exact dependency version:
- Restricts code generation to APIs available in your active release.
- Audits existing code for breaking changes across releases (such as `correlation(with:)` returning an optional from 1.2.5, or new `DistanceMetric` cases in 1.6.0).
- Suggests targeted fixes with before-and-after diffs.

## Installation

### Claude Code

Install the skill from the marketplace:

```bash
/plugin install quiver --marketplace waynewbishop/quiver-agent-skill
```

To enable the skill for all team members on a project, install it with project scope and commit the resulting `.claude/settings.json`:

```bash
claude plugin marketplace add waynewbishop/quiver-agent-skill --scope project
```

### Other Coding Agents (Agent Skills standard)

If we use Cursor, Codex, or another agent supporting the open [Agent Skills](https://agentskills.io) standard, install via `npx`:

```bash
npx skills add https://github.com/waynewbishop/quiver-agent-skill --skill quiver-swift-ml
```

## Using the Skill

In any repository containing a Quiver dependency, Claude loads the skill automatically when we ask for numerical or statistical code:

> "Fit a logistic regression model on these features and print the classification report."

> "Check this target for any deprecated Quiver calls before we upgrade to 1.6.0."

To invoke the skill directly or restrict Claude's focus:

- `/quiver-swift-ml Review our statistics extensions for optional safety`
- `/quiver-swift-ml Check for breaking changes since 1.2.0`

The skill activates only when working with Quiver and will never modify your `Package.swift` without explicit confirmation.

## Architecture

The reference files in `quiver/skills/quiver-swift-ml/reference/` are generated directly from Quiver's tagged releases, not maintained by hand.

`scripts/generate-reference.swift` inspects Quiver's compiled interface to build:
1. Declarations, DocC summaries, and version availability tags for every public symbol.
2. A release-by-release log of deprecations and renames.

To regenerate reference files against a local checkout of Quiver:

```bash
swift scripts/generate-reference.swift
```

To run the eval suite:

```bash
claude plugin eval quiver
```

## License

Apache 2.0. See [LICENSE](LICENSE).
