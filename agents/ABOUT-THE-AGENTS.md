# Subagents for Claude Code

This document describes the specialized development agents and how they work together to deliver complete, production-ready projects across any language or platform.

## Overview

The agent ecosystem is organized with **Main Claude as the coordinator** that consults specialized agents. This architecture provides:

- **Main Claude coordinates**: Creates plans, delegates to specialists, tracks progress
- **Separation of concerns**: Each agent focuses on one specialized domain
- **Context efficiency**: Patterns stored in Cognee, not embedded in agents
- **Composability**: Agents can be used independently or orchestrated together
- **Maintainability**: Updates to one agent don't affect others

## Agent Hierarchy

```mermaid
graph TD
User[User Request] --> Main[Main Claude<br/>Coordinator]

    Main --> SoftArch[solutions-architect<br/>Language-Agnostic<br/>Architecture]

    SoftArch --> LangArch[Language-Specific<br/>Architects]

    LangArch --> LangSpecArch[Language Architects<br/>Go]

    Main --> APIArch[api-architect<br/>Language-Agnostic<br/>API Specs]
    Main --> DataArch[data-architect<br/>Schema Design]
    Main --> Impl[Implementation]
    Main --> Test[Testing]
    Main --> DevOps[Deployment]
    Main --> Doc[Documentation]
    Main --> Review[Code Review]

    Impl --> SoftEng[software-engineer<br/>Go, Python, .NET, React, Shell]
    Impl --> DataEng[data-engineer<br/>SQL, Cypher]
    Test --> E2EEng[e2e-test-engineer<br/>Go, BATS]
    DevOps --> DevOpsEng[devops-engineer]
    Doc --> DocEng[technical-writer]
    Review --> CodeReview[code-reviewer]

    style Main fill:#2c3e50,stroke:#1a252f,color:#fff
    style SoftArch fill:#9b59b6,stroke:#8e44ad,color:#fff
    style LangArch fill:#8e44ad,stroke:#7d3c98,color:#fff
    style LangSpecArch fill:#9b59b6,stroke:#8e44ad,color:#fff
    style APIArch fill:#e67e22,stroke:#d35400,color:#fff
    style SoftEng fill:#27ae60,stroke:#229954,color:#fff
    style E2EEng fill:#27ae60,stroke:#229954,color:#fff
    style DevOpsEng fill:#3498db,stroke:#2980b9,color:#fff
    style DocEng fill:#95a5a6,stroke:#7f8c8d,color:#fff
    style DataArch fill:#e67e22,stroke:#d35400,color:#fff
    style DataEng fill:#27ae60,stroke:#229954,color:#fff
    style CodeReview fill:#e74c3c,stroke:#c0392b,color:#fff
    style Impl fill:#34495e,stroke:#2c3e50,color:#fff
    style Test fill:#34495e,stroke:#2c3e50,color:#fff
    style DevOps fill:#34495e,stroke:#2c3e50,color:#fff
    style Doc fill:#34495e,stroke:#2c3e50,color:#fff
    style Review fill:#34495e,stroke:#2c3e50,color:#fff

```

## Requirements Gathering Phase

**When you have a business need**, Main Claude consults solutions-architect for architectural guidance:

```mermaid
sequenceDiagram
participant User
participant Main as Main Claude
participant SoftArch as solutions-architect
participant LangArch as language-architect

    User->>Main: "I need to build something for my users"
    Main->>SoftArch: Consults solutions-architect

    Note over SoftArch: Asks clarifying questions

    SoftArch->>User: What is the purpose?
    User->>SoftArch: User management system

    SoftArch->>User: Who are the users? (Web/mobile/internal?)
    User->>SoftArch: Web and mobile clients

    SoftArch->>User: What operations are needed?
    User->>SoftArch: CRUD users, auth, roles

    SoftArch->>User: Scale/performance requirements?
    User->>SoftArch: 10k users, moderate traffic

    SoftArch->>User: Preferred language/platform?
    User->>SoftArch: Go

    Note over SoftArch: Analyzes requirements
    Note over SoftArch: High-level: REST API + K8s + Go

    SoftArch->>Main: High-level architecture: REST API + K8s + Go<br/>Hand off to language-architect
    Main->>User: Here's the high-level architecture recommendation
    User->>Main: Approved, proceed

    Main->>LangArch: Translate to implementation plan
    Note over LangArch: Chooses frameworks and tooling<br/>Defines project structure

    LangArch->>Main: Detailed implementation plan
    Note over Main: Creates implementation plan with TodoWrite
    Note over Main: Delegates to specialists using Task tool

```

**Key Point**: You don't need formal specs or technical documents upfront. Here's how it works:

1. **Main Claude consults solutions-architect** for high-level architecture recommendations
2. **solutions-architect asks questions** to understand business needs and constraints
3. **solutions-architect recommends high-level architecture** (API style, platform, deployment)
4. **User approves** the high-level architecture
5. **Main Claude delegates to language-specific architect** (go-software-architect, etc.)
6. **Language architect creates detailed implementation plan** (specific frameworks, structure, patterns)
7. **Main Claude creates plan** using TodoWrite
8. **Main Claude delegates** to specialists using Task tool

**Example Starting Points**:

- "I need an API for managing user accounts in my SaaS product"
- "Build a CLI tool for our ops team to manage cloud resources"
- "We need a real-time notification system for our mobile app"
- "Add real-time notifications to our existing Python API"
- NOT: "Implement the UserService as defined in spec-v2.3.pdf" (too specific, skip straight to language engineer)

## Common Workflows

### Workflow 1: New REST API Service (Greenfield)

```mermaid
sequenceDiagram
participant User
participant Main as Main Claude
participant SoftArch as solutions-architect
participant LangArch as language-architect
participant APIArch as api-architect
participant Eng as software-engineer
participant E2E as e2e-test-engineer
participant DevOps as devops-engineer

    User->>Main: "Build a user management API"
    Main->>SoftArch: Get high-level architecture
    SoftArch-->>Main: Recommend: REST API + Go + Docker + GH Actions

    Note over User,Main: User approves

    Main->>LangArch: Translate to implementation plan
    LangArch-->>Main: Detailed plan with frameworks and structure

    Note over Main: Creates plan with TodoWrite

    Main->>APIArch: Design REST API spec for users
    APIArch-->>Main: user-api.yaml (OpenAPI)

    Main->>Eng: Implement handlers from spec
    Eng-->>Main: Handlers + services + repos

    Main->>E2E: Create tests from OpenAPI spec
    E2E-->>Main: E2E test suite

    Main->>DevOps: Create Docker + GH Actions
    DevOps-->>Main: Dockerfile + workflows

    Main-->>User: Complete API service

```

### Workflow 2: Adding Feature to Existing Project (Brownfield)

```mermaid
sequenceDiagram
participant User
participant Main as Main Claude
participant SoftArch as solutions-architect
participant LangArch as language-architect
participant Eng as software-engineer
participant E2E as e2e-test-engineer

    User->>Main: "Add real-time notifications to our existing API"
    Main->>SoftArch: Analyze existing project + recommend approach

    Note over SoftArch: Scans codebase<br/>Identifies language, stack, CI/CD

    SoftArch-->>Main: Keep existing, add WebSockets

    Note over User,Main: User approves

    Main->>LangArch: Create WebSocket implementation plan
    LangArch-->>Main: Framework/library choice, integration approach

    Note over Main: Creates plan with TodoWrite

    Main->>Eng: Implement WebSocket handlers
    Eng-->>Main: WebSocket implementation integrated

    Main->>E2E: Add WebSocket E2E tests
    E2E-->>Main: Test suite for WebSocket + existing API

    Main-->>User: Feature added with minimal disruption

```

### Workflow 3: New gRPC Microservice with CLI (Greenfield)

```mermaid
sequenceDiagram
participant User
participant Main as Main Claude
participant SoftArch as solutions-architect
participant LangArch as language-architect
participant APIArch as api-architect
participant Eng as software-engineer
participant DevOps as devops-engineer

    User->>Main: "Build user service with mgmt CLI"
    Main->>SoftArch: Get architecture recommendation
    SoftArch-->>Main: Recommend: gRPC + Go + CLI + K8s

    Note over User,Main: User approves

    Main->>LangArch: Translate to implementation plan
    LangArch-->>Main: Framework choices and project structure

    Note over Main: Creates plan with TodoWrite

    Main->>APIArch: Design gRPC proto definitions
    APIArch-->>Main: user.proto

    Main->>Eng: Generate code + implement service and CLI
    Eng-->>Main: gRPC server + CLI implementation

    Main->>DevOps: Create K8s deployment
    DevOps-->>Main: K8s manifests + pipeline

    Main-->>User: Service + CLI + deployment

```

### Workflow 4: GraphQL API with Federation (Greenfield)

```mermaid
sequenceDiagram
participant User
participant Main as Main Claude
participant LangArch as language-architect
participant APIArch as api-architect
participant Eng as software-engineer
participant E2E as e2e-test-engineer

    User->>Main: "Build federated user service"
    Main->>LangArch: Get architecture recommendation
    LangArch-->>Main: Recommend: Apollo Federation

    Note over Main: Creates plan with TodoWrite

    Main->>APIArch: Design federated GraphQL schema
    APIArch-->>Main: user.graphql + federation

    Main->>Eng: Implement resolvers + federation
    Eng-->>Main: GraphQL server with federation

    Main->>E2E: Create GraphQL E2E tests
    E2E-->>Main: Query/mutation tests

    Main-->>User: Federated GraphQL service

```

### Workflow 5: CLI Tool Only (Greenfield)

```mermaid
sequenceDiagram
participant User
participant Main as Main Claude
participant SoftArch as solutions-architect
participant LangArch as language-architect
participant Eng as software-engineer
participant E2E as e2e-test-engineer
participant DevOps as devops-engineer

    User->>Main: "Build identity mgmt CLI"
    Main->>SoftArch: Get architecture recommendation
    SoftArch-->>Main: Recommend: CLI tool + Go + binary releases

    Note over User,Main: User approves

    Main->>LangArch: Create CLI implementation plan
    LangArch-->>Main: Command structure, domains, configuration

    Note over Main: Creates plan with TodoWrite

    Main->>Eng: Implement CLI commands
    Eng-->>Main: Implemented CLI

    Main->>E2E: Create CLI E2E tests
    E2E-->>Main: CLI test suite

    Main->>DevOps: Setup binary releases
    DevOps-->>Main: Release pipeline

    Main-->>User: Complete CLI tool

```

## Cognee Integration

Architecture and specialized agents query the Cognee knowledge graph for patterns before designing:

```mermaid
graph LR
subgraph "Specialized Agents"
SoftArch[solutions-architect]
LangArch[language-architect]
APIArch[api-architect]
SoftEng[software-engineer]
E2EEng[e2e-test-engineer]
DevOpsEng[devops-engineer]
end

    subgraph "Cognee Knowledge Graph"
        Arch_Patterns[Architecture Patterns<br/>- System design<br/>- Technology choices<br/>- CLI patterns]
        API_Patterns[API Patterns<br/>- REST/GraphQL/gRPC specs<br/>- Auth patterns<br/>- Pagination]
        Impl_Patterns[Implementation Patterns<br/>- Language-specific<br/>- Framework usage<br/>- Best practices]
        Test_Patterns[Test Patterns<br/>- E2E testing<br/>- Shell script testing<br/>- Test isolation]
        DevOps_Patterns[DevOps Patterns<br/>- Docker<br/>- K8s<br/>- CI/CD]
    end

    SoftArch <--> Arch_Patterns
    LangArch <--> Arch_Patterns
    LangArch <--> Impl_Patterns
    APIArch <--> API_Patterns
    SoftEng <--> Impl_Patterns
    E2EEng <--> Test_Patterns
    DevOpsEng <--> DevOps_Patterns

    style Arch_Patterns fill:#9b59b6,stroke:#8e44ad
    style API_Patterns fill:#e67e22,stroke:#d35400
    style Impl_Patterns fill:#27ae60,stroke:#229954
    style Test_Patterns fill:#27ae60,stroke:#229954
    style DevOps_Patterns fill:#3498db,stroke:#2980b9

```

### Pattern Query Flow

1. **Agent receives task** from coordinator or user
2. **Agent searches Cognee** using `search()` with appropriate search_type
3. **Agent adapts patterns** to specific requirements
4. **Agent delivers artifacts** (specs, code, tests, configs)

### Why Cognee?

- **Context efficiency**: ~80% reduction in agent size
- **Pattern reuse**: Same patterns across multiple agents
- **Maintainability**: Update patterns once, all agents benefit
- **Separation of concerns**: Agents contain logic, not data

## Decision Trees

### Choosing the Right API Style

```mermaid
graph TD
Start[API Needed?]
Start -->|Yes| Public{Public or Internal?}
Start -->|No| CLI[language-architect<br/>for CLI design only]

    Public -->|Public| Clients{Client Types?}
    Public -->|Internal| Perf{Performance Critical?}

    Clients -->|Web/Mobile<br/>Simple CRUD| REST[api-architect<br/>REST API via OpenAPI]
    Clients -->|Multiple types<br/>Complex queries| GQL[api-architect<br/>GraphQL API]

    Perf -->|Yes<br/>Streaming| GRPC[api-architect<br/>gRPC Service]
    Perf -->|No<br/>Standard| REST2[api-architect<br/>REST API via OpenAPI]

    style REST fill:#f39c12,stroke:#d68910,color:#fff
    style GQL fill:#e91e63,stroke:#c2185b,color:#fff
    style GRPC fill:#3498db,stroke:#2980b9,color:#fff
    style REST2 fill:#f39c12,stroke:#d68910,color:#fff
    style CLI fill:#00bcd4,stroke:#0097a7,color:#fff

```

### Choosing Which Architect to Consult

```mermaid
graph TD
Start[Task Type?]
Start -->|New project<br/>Platform choice open<br/>Brownfield analysis| SoftArch[Main Claude consults<br/>solutions-architect]
Start -->|Language-specific<br/>decisions<br/>Implementation planning| LangArch[Main Claude consults<br/>language-architect]
Start -->|Single component<br/>Known tech stack| Direct{What needs design?}
Start -->|Simple<br/>Implementation only| Eng[Main Claude uses<br/>software-engineer directly]

    SoftArch --> SoftRec[solutions-architect returns<br/>high-level architecture]
    SoftRec --> HandOff[Hand off to language architect]
    HandOff --> LangRec[Language architect returns<br/>detailed implementation plan]
    LangRec --> Plan[Main Claude creates plan<br/>Delegates to specialists]

    LangArch --> LangPlan[language-architect returns<br/>implementation plan]
    LangPlan --> Plan

    Direct -->|API Design| API[Main Claude uses<br/>api-architect directly]
    Direct -->|CLI Design| CLI[Main Claude uses<br/>language-architect directly]
    Direct -->|Testing| E2E[Main Claude uses<br/>e2e-test-engineer directly]
    Direct -->|Deployment| DevOps[Main Claude uses<br/>devops-engineer directly]

    style SoftArch fill:#9b59b6,stroke:#8e44ad,color:#fff
    style LangArch fill:#9b59b6,stroke:#8e44ad,color:#fff
    style Eng fill:#27ae60,stroke:#229954,color:#fff
    style API fill:#e67e22,stroke:#d35400,color:#fff
    style CLI fill:#9b59b6,stroke:#8e44ad,color:#fff
    style E2E fill:#27ae60,stroke:#229954,color:#fff
    style DevOps fill:#3498db,stroke:#2980b9,color:#fff
    style SoftRec fill:#9b59b6,stroke:#8e44ad,color:#fff
    style LangPlan fill:#9b59b6,stroke:#8e44ad,color:#fff
    style HandOff fill:#8e44ad,stroke:#7d3c98,color:#fff
    style LangRec fill:#9b59b6,stroke:#8e44ad,color:#fff
    style Plan fill:#2c3e50,stroke:#1a252f,color:#fff

```

### Utility Agents

#### rlm-subcall

**Role**: Recursive Language Model subagent for large-context processing
**Responsibilities**:

- Process chunks of large documents that exceed context limits
- Support the RLM skill workflow for long-context tasks

**When to use**: Invoked automatically by the `/rlm` skill; not typically used directly.

## Best Practices

### 1. Choose the Right Architect

**For new projects or platform decisions**:

- Consult solutions-architect for high-level architecture
- solutions-architect analyzes existing projects (brownfield)
- solutions-architect hands off to language-specific architect

**For existing language-specific projects**:

- Consult language-architect directly for language-specific decisions
- language-architect translates high-level architecture to implementation plans
- language-architect recommends frameworks and patterns

### 2. Respect Existing Projects

When working with brownfield projects:

- solutions-architect scans codebase to understand what exists
- Preserve working CI/CD, infrastructure, and patterns
- Incremental improvements over rewrites
- Migration paths for necessary changes

### 3. Main Claude Coordinates Implementation

After architecture recommendations:

- Create implementation plan with TodoWrite
- Delegate to specialists using Task tool
- Track progress through each phase
- Ensure consistency across components

### 4. Use Specialized Agents for Design

Let each specialist design their domain:

- api-architect for all API specifications (OpenAPI/GraphQL/gRPC)
- Language architects for CLI command structures and patterns
- DevOps engineers for deployment

### 5. Generate Code from Specs

Never hand-write API types:

- OpenAPI → `oapi-codegen` (Go), or language-specific generators
- GraphQL → `gqlgen` (Go), or language-specific generators
- gRPC → `buf generate` (multi-language)

### 6. Test Against Specs

Use E2E tests to validate implementation:

- Tests should match API specifications exactly
- Black-box testing from user perspective
- Validate both success and error scenarios

### 7. Sequence Work Properly

Main Claude follows this order:

1. Consult solutions-architect (new projects/platform decisions) OR language-architect (language-specific)
2. Language-architect creates detailed implementation plan including CLI design if applicable
3. Design API specs (delegate to api-architect if API project)
4. Generate code from specs (language-architect chooses generators)
5. Implement business logic and CLI commands (delegate to software-engineer)
6. Wire handlers/resolvers/commands
7. Write E2E tests (delegate to e2e-test-engineer)
8. Create deployment artifacts (delegate to devops-engineer)

## Example: Complete Project Flow

Here's how to build a complete SaaS API project using the agent ecosystem:

```bash
# 1. User starts with a business need (no technical spec required)
User: "I need to build a SaaS application for managing teams and projects."

# 2. Main Claude consults solutions-architect
Main Claude: [Uses Task tool with solutions-architect]

# 3. solutions-architect asks clarifying questions
solutions-architect: "Let me understand your requirements:
  - Who are the users? (web, mobile, internal systems?)
  - What operations do you need? (CRUD, real-time updates?)
  - How many users/what scale?
  - Deployment preferences?"

User: "Web and mobile clients. Users and organizations with role-based access.
       Real-time notifications when projects update. Start with 1000 orgs,
       plan to scale. Deploy to Kubernetes on AWS."

# 4. solutions-architect returns recommendations and hands off
solutions-architect: "Architecture Recommendation:
  - GraphQL API (multiple clients, real-time subscriptions)
  - gRPC for internal microservices (high performance)
  - Ops CLI for management
  - Kubernetes deployment (K8s + Helm)
  - GitHub Actions CI/CD
  - Go as implementation language

  Next: Hand off to language-architect (go-software-architect) for detailed implementation plan"

# 5. Main Claude delegates to language-architect
Main Claude: [Uses Task tool with go-software-architect]

# 6. language-architect returns detailed plan
language-architect: "Implementation Plan:
  - gqlgen for GraphQL, buf for gRPC, Cobra for CLI
  - Project structure: cmd/, internal/, api/
  - Domain-based organization

  Next Steps for Main Claude:
  1. Delegate to api-architect for GraphQL schema and gRPC proto definitions
  2. Delegate to software-engineer for implementation (GraphQL, gRPC, CLI)
  3. Delegate to e2e-test-engineer for testing
  4. Delegate to devops-engineer for deployment"

# 7. Main Claude presents plan to user
User: "Looks good, proceed."

# 8. Main Claude creates implementation plan
Main Claude: [Uses TodoWrite to create phased plan]

# 9. Main Claude delegates to specialists (using Task tool)
# Phase 1: API Design
# → api-architect designs GraphQL schema and gRPC definitions
# Phase 2: Implementation
# → software-engineer implements GraphQL, gRPC, and CLI
# Phase 3: Testing
# → e2e-test-engineer creates test suite
# Phase 4: Deployment
# → devops-engineer creates K8s + CI/CD

# Result: Complete production-ready SaaS API
#   - User provided business needs in natural language
#   - solutions-architect created high-level architecture
#   - language-architect translated to detailed implementation plan
#   - Main Claude coordinated implementation
#   - Specialists designed and implemented each piece
#   - All components work together as a cohesive system
```

## Agent Color Coding

For quick visual identification in Claude Code:

- **Purple** - solutions-architect (language-agnostic), language-architect (language-specific implementation)
- **Orange** - api-architect (REST/GraphQL/gRPC specifications), data-architect (schema design)
- **Green** - software-engineer (implementation for all languages), e2e-test-engineer (testing), data-engineer (SQL/Cypher)
- **Red** - code-reviewer (pattern compliance and code review)
- **Blue** - devops-engineer (deployment and CI/CD)
- **Gray** - technical-writer (documentation)

## Summary

The agent ecosystem provides:

- **Main Claude coordinates** - Creates plans with TodoWrite, delegates with Task tool, tracks progress
- **solutions-architect consults** - Translates business needs to high-level architecture recommendations
- **language-architect plans** - Translates high-level architecture to detailed implementation plans
- **No formal specs required** - Start with natural language, architects ask clarifying questions
- **Multi-language support** - Same workflow for Go, Python, .NET, and shell scripts
- **Separation of concerns** - Each agent has one focused responsibility
- **Context efficiency** - Patterns in Cognee, not embedded in agents
- **Composability** - Use agents independently or orchestrated together
- **Maintainability** - Update one agent without affecting others
- **Scalability** - Add new languages without redesigning

**Getting Started**:

- **Complex projects**: Main Claude consults solutions-architect for high-level architecture, then language-architect for implementation plan, then coordinates specialists
- **Language-specific projects**: Main Claude consults language-architect directly, then coordinates specialists
- **Single component**: Main Claude delegates directly to specialist (api-architect, software-engineer, etc.)
- **Simple tasks**: Main Claude uses software-engineer directly for implementation
- **Don't have architecture?** Main Claude consults solutions-architect (language-agnostic) or language-architect (language-specific) to create it through conversation
