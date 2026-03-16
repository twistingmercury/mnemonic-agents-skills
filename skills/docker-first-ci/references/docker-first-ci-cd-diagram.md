# Docker-First CI/CD Reference Example

This is an organization-level reference example for Docker-first delivery pipelines.
It is intentionally generic and not tied to one language, runtime, or registry.

```mermaid
flowchart TD
    A["Code change merged to protected branch or release tag"] --> B["CI trigger"]

    subgraph CI0[CI workflow]
    C["Build OCI image from Dockerfile"] --> D["Quality gates in container
    lint / static analysis / unit tests / vuln scan"]
    D --> E["Integration or E2E tests"]
    E --> F{"All gates pass?"}
    F -->|No| G["Fail CI and publish logs/reports"]
    F -->|Yes| H["Generate SBOM and provenance"]
    H --> I["Push immutable image by digest"]
    I --> J["Publish CI artifact metadata
    digest / version / commit / reports"]
    end

    B --> C

    J --> K{"CD trigger policy satisfied?
    push / tag / manual approval"}
    K -->|No| L["Stop"]
    K -->|Yes| M

    subgraph CD0[CD workflow]
    M["Resolve promoted image digest
    never rebuild in CD"] --> N["Deploy to target environment"]
    N --> O["Run post-deploy checks
    health / smoke / canary"]
    O --> P{"Checks pass?"}
    P -->|No| Q["Rollback and alert"]
    P -->|Yes| R["Promote or mark release successful"]
    end
```
