# Template tokens

Replace every occurrence before building:

| Token | Example | Meaning |
| --- | --- | --- |
| `{{API_NAME}}` | `Inventory` | PascalCase API/root namespace name |
| `{{RESOURCE_SINGULAR}}` | `Product` | PascalCase singular resource name |
| `{{RESOURCE_PLURAL}}` | `Products` | PascalCase plural resource name |
| `{{RESOURCE_ROUTE}}` | `products` | Lowercase plural route segment |

The supplied resource has only an `Id` and `Name`, making it a coherent smoke-test baseline rather than a domain model. Change or replace its model, validation, and persistence mapping to suit the actual requirements.
