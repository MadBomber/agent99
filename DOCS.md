# Agent99 Documentation

This repository uses [MkDocs](https://www.mkdocs.org/) with the [Material theme](https://squidfunk.github.io/mkdocs-material/) to generate comprehensive documentation for the Agent99 framework.

## 📚 Documentation Structure

```
docs/
├── index.md                    # Homepage
├── getting-started/           # Installation and quick start guides
├── core-concepts/            # Fundamental concepts and architecture
├── framework-components/     # Deep dive into system components
├── agent-development/       # Guide to building agents
├── advanced-topics/        # Advanced features and protocols
├── api-reference/          # API documentation
├── operations/             # Configuration, security, troubleshooting
├── examples/              # Code examples and tutorials
└── assets/               # Images, diagrams, and other assets
```

## 🚀 Building the Documentation

### Prerequisites

Install MkDocs and required dependencies:

```bash
pip install mkdocs mkdocs-material
```

### Build and Serve Locally

```bash
# Serve the documentation locally (auto-reloads on changes)
mkdocs serve

# Build static documentation
mkdocs build

# Deploy to GitHub Pages (if configured)
mkdocs gh-deploy
```

The documentation will be available at `http://localhost:8000` when serving locally.

## 📖 Key Documentation Sections

- **[Getting Started](docs/getting-started/overview.md)** - New to Agent99? Start here!
- **[Core Concepts](docs/core-concepts/what-is-an-agent.md)** - Understand agents and architecture
- **[Framework Components](docs/framework-components/agent-registry.md)** - How the system works
- **[Agent Development](docs/agent-development/custom-agent-implementation.md)** - Build your own agents
- **[Examples](docs/examples/basic-examples.md)** - Working code examples

## 🎨 Documentation Features

The documentation includes:

- **Navigation tabs** for easy browsing
- **Search functionality** with instant results
- **Code syntax highlighting** for Ruby and other languages
- **Mermaid diagram support** for architecture diagrams
- **Dark/light theme toggle** for comfortable reading
- **Mobile-responsive design** for all devices
- **Direct GitHub integration** for easy editing

## 📝 Contributing to Documentation

1. **Edit existing pages**: Navigate to the appropriate markdown file in the `docs/` directory
2. **Add new pages**: Create new markdown files and update the navigation in `mkdocs.yml`
3. **Add images**: Place images in `docs/assets/` and reference them with relative paths
4. **Test changes**: Run `mkdocs serve` to preview your changes locally

## 🔗 Links

- **Live Documentation**: [https://madbomber.github.io/agent99](https://madbomber.github.io/agent99) (when deployed)
- **Repository**: [https://github.com/MadBomber/agent99](https://github.com/MadBomber/agent99)
- **RubyGems**: [https://rubygems.org/gems/agent99](https://rubygems.org/gems/agent99)

## 📋 Documentation TODO

Missing documentation files that should be created:

- `docs/getting-started/quick-start.md` - Quick setup guide
- `docs/getting-started/basic-example.md` - Step-by-step first agent
- `docs/core-concepts/agent-types.md` - Server, Client, Hybrid agents
- `docs/agent-development/request-response-handling.md` - Message handling patterns
- `docs/advanced-topics/multi-agent-processing.md` - Running multiple agents
- `docs/api-reference/agent99-base.md` - Core API documentation
- `docs/api-reference/registry-client.md` - Registry API docs
- `docs/api-reference/message-clients.md` - Messaging API docs
- `docs/api-reference/schemas.md` - Schema definitions
- `docs/examples/advanced-examples.md` - Complex examples

---

*The documentation is organized to provide a clear learning path from basic concepts to advanced topics, making Agent99 accessible to developers at all levels.*