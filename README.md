# SwiftVerificar Package Collection

A [Swift Package Collection](https://swift.org/blog/package-collections/) for the **SwiftVerificar** ecosystem — a native Swift port of [veraPDF](https://github.com/veraPDF) for PDF/A and PDF/UA validation.

## Included Packages

| Package | Description | Ports |
|---------|-------------|-------|
| **SwiftVerificar-biblioteca** | Main integration library | [veraPDF-library](https://github.com/veraPDF/veraPDF-library) |
| **SwiftVerificar-parser** | PDF parsing, structure trees, XMP metadata | [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser) |
| **SwiftVerificar-validation** | Validation engine, feature reporting | [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation) |
| **SwiftVerificar-validation-profiles** | XML validation rules for PDF/A and PDF/UA | [veraPDF-validation-profiles](https://github.com/veraPDF/veraPDF-validation-profiles) |
| **SwiftVerificar-wcag-algs** | WCAG accessibility algorithms | [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs) |

## Why SwiftVerificar?

The original veraPDF is written in Java, requiring a JVM runtime. SwiftVerificar provides:

- **Native Swift** — No Java dependency
- **Apple Silicon optimized** — Native ARM64 binaries
- **Swift concurrency** — Modern async/await APIs
- **Apple framework integration** — Works with PDFKit, Core Graphics

## Adding the Collection

### In Xcode

1. Open Xcode
2. Go to **File > Add Package Collections...**
3. Click the **+** button
4. Enter the URL: `https://raw.githubusercontent.com/intrusive-memory/SwiftVerificar/main/collection.json`
5. Click **Add**

### Using Swift CLI

```bash
swift package-collection add https://raw.githubusercontent.com/intrusive-memory/SwiftVerificar/main/collection.json
```

To search packages in the collection:

```bash
swift package-collection search --keywords pdf validation
```

## Primary Consumer

[Lazarillo](https://github.com/intrusive-memory/Lazarillo) — PDF accessibility remediation engine for macOS. SwiftVerificar enables Lazarillo to validate PDF/UA-2 compliance without requiring Java.

## Development

See [AGENTS.md](AGENTS.md) for development guidelines, implementation roadmap, and architecture decisions.

## License

This project is licensed under the same terms as the original veraPDF (GPLv3+ / MPLv2+).
