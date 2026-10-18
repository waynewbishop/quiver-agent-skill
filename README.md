# Quiver Agent Skill

[![Quiver](https://img.shields.io/badge/Quiver-1.0.0–1.6.0-blue)](https://github.com/waynewbishop/quiver)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

An agent skill that gives your AI coding assistant a verified reference of [Quiver](https://github.com/waynewbishop/quiver)'s public API — every signature, label, and deprecation across releases 1.0.0 through 1.6.0. Generated code adheres to Quiver's exact type signatures, safe optional handling, and architectural conventions from the first prompt, and reviews stay scoped to the version your project actually depends on.

## Who the Skill is for

- **Students** working through a course, textbook, or self-study get an AI assistant that writes correct Quiver code without guessing at signatures, so the focus stays on mathematical concepts rather than debugging invalid syntax.
- **Educators** preparing lectures, problem sets, and course modules get generated examples and starter code that align with Quiver's canonical API — across applied linear algebra, descriptive statistics, regression, and clustering.
- **Apple-platform developers** prototyping models or integrating numerical computing into iOS, macOS, watchOS, or visionOS apps get verified API signatures, safe optional handling, and upgrade audits across releases.

## Why Use the Skill

### 1. Accurate API signatures and labels

Claude looks up exact signatures before writing, eliminating common hallucinations:

- Uses current symbol names (e.g., `standardDeviation()`, renamed from `std()` in 1.2.0) and ignores renames the release notes announced but never shipped, such as `indexOfMaximum`
- Supplies mandatory parameters like `seed: UInt64` for reproducible operations
- Distinguishes classification labels (`labels: [Int]`) from regression targets (`targets: [Double]`)

### 2. Preventing silent logic bugs

Because Quiver builds directly on Swift's standard `Array`, general models easily confuse language behavior with framework operations:

- **Vector math:** In Swift, `a + b` concatenates two arrays. The skill ensures Claude calls `a.add(b)` or `a.subtract(b)` for element-wise arithmetic.
- **Optional safety:** Statistics that can be undefined (`mean()`, `correlation(with:)`) return optionals. The skill prevents force-unwraps (`!`) that crash on empty data.
- **Model convergence:** Iterative algorithms (`LogisticRegression`, `GradientDescent`) depend on feature scale. The skill wraps them in `Pipeline` with `StandardScaler` and checks that `outcome == .converged`.

### 3. Version-aware reviews and upgrades

Ask Claude to review an existing project or prepare for an upgrade, and the skill reads `Package.resolved` to determine your exact dependency version:

- Restricts code generation to APIs available in your active release
- Audits existing code for breaking changes across releases (such as `correlation(with:)` returning an optional from 1.2.5, or new `DistanceMetric` cases in 1.6.0)
- Suggests targeted fixes with before-and-after diffs

## Installation

### Claude Code

Add the marketplace, then install the skill from it:

```bash
/plugin marketplace add waynewbishop/quiver-agent-skill
/plugin install quiver@quiver-agent-skill
```

To enable the skill for all team members on a project, add the marketplace and install the plugin with project scope, then commit the resulting `.claude/settings.json`:

```bash
claude plugin marketplace add waynewbishop/quiver-agent-skill --scope project
claude plugin install quiver@quiver-agent-skill --scope project
```

### Other Coding Agents (Agent Skills standard)

With Cursor, Codex, or another agent supporting the open [Agent Skills](https://agentskills.io) standard, install via `npx`:

```bash
npx skills add https://github.com/waynewbishop/quiver-agent-skill --skill quiver-swift-ml
```

## Using the Skill

In any repository containing a Quiver dependency, Claude loads the skill automatically when you ask for numerical or statistical code:

> "Fit a logistic regression model on these features and print the classification report."

> "Check this target for any deprecated Quiver calls before we upgrade to 1.6.0."

To invoke the skill directly or restrict Claude's focus:

- `/quiver-swift-ml Review our statistics extensions for optional safety`
- `/quiver-swift-ml Check for breaking changes since 1.2.0`

The skill activates only when working with Quiver and will never modify your `Package.swift` without explicit confirmation.

## Architecture

The reference files in `quiver/skills/quiver-swift-ml/reference/` are generated directly from Quiver's tagged releases, not maintained by hand.

`scripts/generate-reference.swift` inspects Quiver's compiled interface to build:

1. Declarations, DocC summaries, and version availability tags for every public symbol
2. A release-by-release log of deprecations and renames

To regenerate reference files, check out Quiver next to this repository (or pass `--quiver <path>`) and install the GitHub CLI (`gh`), which the script uses to fetch release notes:

```bash
swift scripts/generate-reference.swift
```

To run the eval suite from the repository root:

```bash
claude plugin eval ./quiver
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Apache 2.0. See [LICENSE](LICENSE).

## Newsletter

[The Feature Vector](https://featurevector.substack.com) — a newsletter about ML intuition for engineers, built in Swift. One idea per issue, with a recipe you can run in Xcode.
