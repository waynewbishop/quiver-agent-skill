---
type: llm
weight: 2
---

PASS if the element-wise sum uses Quiver's add(_:) method (a.add(b)) or an explicit loop, and the matrix product uses multiplyMatrix(_:).
FAIL if the element-wise sum is written as a + b on two [Double] arrays (Swift's + concatenates arrays), or the matrix product uses multiply(_:) (element-wise) or an invented operator.
