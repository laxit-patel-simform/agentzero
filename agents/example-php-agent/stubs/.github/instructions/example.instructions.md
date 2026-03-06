---
applyTo: ["app/**/*.php", "src/**/*.php"]
---
# Framework Guidelines
- **Laravel:** Prefer Eloquent over raw DB queries. Use Service classes for complex business logic.
- **Symfony:** Use Dependency Injection (constructor-based). Avoid `ServiceLocator`.
- **General:** Ensure all public methods have return types (PHP 8.1+).
