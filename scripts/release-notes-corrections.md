# Release-note corrections

Corrections to Quiver's published release notes, verified against the public API of each tagged release. `generate-reference.swift` appends each `## <version>` section below to that version's entry in `reference/changes.md`. Add a section here whenever a release note disagrees with the tagged source; remove it once the release note itself is fixed.

## 1.1.0

The renames listed below for this release did not ship. In every tagged release from 1.0.0 through 1.6.0, `argMin()` and `argMax()` keep those names, and `indexOfMinimum`/`indexOfMaximum` do not exist. `cumulativeSum()` and `cumulativeProduct()` already had those names in 1.0.0; `cumSum` and `cumProd` were never public. The quartiles field is still `iqr`. Do not flag or rewrite any of these names.

## 1.2.0

The `Quartiles` struct that `quartiles()` returns names its interquartile-range field `iqr`, not `interquartileRange` as the upgrade notes below say. Code that read the 1.1.0 tuple's `.iqr` field keeps compiling.
