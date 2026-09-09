# Reference project shape

Use this as a structural guide, not a fixed domain template. The bundled `assets/full-project` tree implements this layout; replace the initial resource model with the user's domain.

```text
<repository>/
├── src/
│   ├── <ApiName>/
│   │   ├── DataAccess/
│   │   │   ├── DTOs/
│   │   │   └── <Resource>DbContext.cs
│   │   ├── Endpoints/
│   │   │   └── <Resource>Endpoints.cs
│   │   ├── Handlers/
│   │   │   └── <Resource>Handlers.cs
│   │   ├── Models/
│   │   │   └── <Resource>.cs
│   │   ├── Properties/launchSettings.json
│   │   ├── Program.cs
│   │   ├── appsettings.Development.json
│   │   ├── appsettings.json
│   │   └── <ApiName>.csproj
│   ├── Tests/
│   │   ├── Unit/
│   │   └── BlackBox/
│   └── <Solution>.slnx
├── database/
│   ├── sql/
│   ├── Dockerfile
│   └── build.sh
├── build/
│   ├── Dockerfile
│   ├── build.sh
│   ├── test-black-box.sh
│   └── tests/
├── deploy/
│   ├── <api>/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── envoy/
│       ├── Chart.yaml
│       ├── envoy.yaml
│       └── templates/
├── scripts/
├── .github/workflows/
├── docker-compose.yaml
├── Makefile
└── README.md
```

Base API shape:

1. `Program` registers OpenAPI, the database context, and handler interfaces; maps OpenAPI/UI and the resource endpoints.
2. A resource extension method uses `MapGroup("/<resources>")`, assigns a tag, and maps its operations.
3. Each endpoint receives an interface handler through dependency injection and returns typed HTTP results.
4. The handler owns EF Core queries, writes, and translation from persistence DTOs to API response models.
5. The database context exposes only needed `DbSet`s. Keep persistence-specific configuration and DTOs out of endpoint contracts.

The reference project uses conventional API routes such as `GET /orders/get`, `GET /orders/get/{id:guid}`, `POST /orders/create`, and `DELETE /orders/delete/{id:guid}`. Prefer conventional REST resource paths for new projects (`GET /orders`, `GET /orders/{id}`, `POST /orders`, `DELETE /orders/{id}`) unless the user specifically wants the reference route naming.
