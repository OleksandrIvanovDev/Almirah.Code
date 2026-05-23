# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/doc_parser_spec.rb

# Run a specific test by line number or name
bundle exec rspec spec/doc_parser_spec.rb:15
bundle exec rspec spec/doc_parser_spec.rb -e "Recognizes Heading1"

# Lint
rubocop
```

The `.rspec` file sets defaults: color output, doc format, random order.

## Architecture

Almirah is a Ruby gem (CLI via Thor) that processes Markdown-based ALM (Application Lifecycle Management) projects into interlinked HTML with traceability.

### Pipeline

`project.rb` orchestrates: **Parse → Link → Check → Index → Render**

1. **Parse** — `doc_parser.rb` reads Markdown specs; `source_file_parser.rb` reads implementation files (C, C++, Python, Java, Ruby, JS, TS, Go, Rust). Frontmatter (YAML) is supported.
2. **Link** — `doc_linker.rb` cross-references all documents. Items reference each other via IDs (e.g. `[REQ-001]`). Links from tests to specs use `>[SPEC-ID]`; links from source code use `<REQ>...</REQ>` XML tags.
3. **Check** — detects broken/dangling references.
4. **Index** — builds a searchable overview page using Orama (client-side search).
5. **Render** — each document type calls `to_html`, outputs into `<project>/build/` using `templates/page.html`, CSS, and JS assets.

### Key Document Types (`lib/almirah/doc_types/`)

| Type | Purpose |
|------|---------|
| `Specification` | Requirements/design docs with controlled items |
| `Protocol` | Test protocols linked to specifications |
| `SourceFile` | Implementation files linked to specifications |
| `Traceability` | Matrix of spec→spec upstream/downstream links |
| `Coverage` | Matrix of test protocol → specification coverage |
| `Implementation` | Matrix of source file → specification links |
| `Index` | Main navigation/overview page |
| `Decision` | Decision record (ADR / issue / enhancement) parsed from `<project>/decisions/` |
| `DecisionsOverview` | Listing page rendered to `build/decisions/overview.html` |

### Key Concepts

- **Controlled Items**: Paragraphs or table rows with explicit IDs (e.g. `[REQ-001] description`). These are the traceable units.
- **Up-links**: References from a lower-level item to a higher-level one (test → spec, impl → spec).
- **Down-links**: Reverse references automatically calculated during linking.
- **Two-pass processing**: First pass collects all IDs; second pass resolves links.

### Configuration

Projects use a `project.yml` at the project root (parsed by `project_configuration.rb`) to configure input/output paths and repositories.

### Entry Point

`lib/almirah.rb` — Thor-based CLI with three commands:
- `almirah please <project_folder>` — process project
- `almirah create <project_name>` — scaffold new project
- `almirah combine <project_folder>` — merge test protocols

## Project Documents

Project requirements and other documents are created using the same format and folders structure that is native for Almirah framewotk.

Documents are located in @./../Almirah.Doc
