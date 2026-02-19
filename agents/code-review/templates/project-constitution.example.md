# Project Constitution - [Your Project Name]

> **What is this?** A living document that describes your project's critical rules, patterns, and domain context.
> The **Functional Review Agent** uses this to validate that PRs respect your project's business logic and architecture decisions.
>
> **How to use:** Copy this template, fill in your project's specifics, and save as `project-constitution.md` in your repository root.
> If this file is missing, the functional review agent will still run but with lower confidence.

---

## 1. Project Overview

**Domain:** E-commerce SaaS platform
**Primary Language:** PHP 8.2+
**Framework:** Symfony 6.4 / Laravel 10+
**Architecture:** Monolithic with service layer

### Business Context
> Describe what your application does and who uses it.

This platform handles online order management for small-to-medium merchants. Core flows include product catalog management, order processing, payment handling, and shipping coordination.

---

## 2. Domain Vocabulary

> Define terms that have specific meaning in your codebase. Agents use this to understand intent.

| Term | Definition | Code Location |
|------|-----------|---------------|
| Order | A customer purchase containing one or more line items | `src/Entity/Order.php` |
| Fulfillment | The process of picking, packing, and shipping an order | `src/Service/FulfillmentService.php` |
| SKU | Stock Keeping Unit - unique product variant identifier | `src/Entity/Product.php::sku` |
| Cart | Temporary collection of items before checkout | `src/Entity/Cart.php` |
| Merchant | Business owner who manages products and orders | `src/Entity/Merchant.php` |

---

## 3. Critical Business Rules

> Rules that must NEVER be violated. The functional review agent treats violations as **critical** findings.

### 3.1 Order Processing
- Orders MUST transition through states in order: `draft -> pending -> confirmed -> fulfilled -> completed`
- An order in `fulfilled` state CANNOT be modified (only cancelled)
- Order totals MUST be recalculated when line items change (never cache stale totals)
- All monetary values are stored as integers in cents (e.g., `$19.99` = `1999`)

### 3.2 Payment Handling
- Payment MUST be captured before order confirmation
- Failed payments MUST NOT advance order state
- Refunds require a completed payment record to exist
- All payment operations MUST be idempotent (use idempotency keys)

### 3.3 User Authorization
- Merchants can only access their own orders and products
- Admin users can access all resources but MUST have audit logging
- API tokens expire after 24 hours and MUST be refreshed

---

## 4. Architecture Decisions

> Patterns your team has agreed on. Deviations should be flagged.

### 4.1 Service Layer
- **All business logic** lives in Service classes, never in Controllers or Models/Entities
- Controllers are thin: validate input, call service, return response
- Services are injected via constructor (no service locator pattern)

### 4.2 Database Access
- **Repository pattern** for all database queries
- No raw SQL in application code (use ORM query builders)
- All list endpoints MUST be paginated (no unbounded queries)
- Bulk operations use batch processing, not loops

### 4.3 Event-Driven Side Effects
- Side effects (emails, notifications, audit logs) are triggered via domain events
- Events are dispatched AFTER the primary operation succeeds
- Event handlers MUST be idempotent

### 4.4 Error Handling
- Business rule violations throw domain-specific exceptions (e.g., `InsufficientStockException`)
- Never catch `\Exception` broadly in service methods
- API responses use consistent error format with error codes

---

## 5. Forbidden Patterns

> Code patterns that are explicitly banned. The agent flags these as **high severity**.

| Pattern | Why It's Forbidden | What To Use Instead |
|---------|-------------------|-------------------|
| `$entity->save()` in controllers | Business logic leaks into controllers | Call a service method |
| `new DateTime()` without timezone | Timezone bugs in multi-region deployments | Use `new DateTimeImmutable('now', new DateTimeZone('UTC'))` |
| `sleep()` in application code | Blocks PHP-FPM workers | Use queue jobs for delays |
| `var_dump()` / `dd()` | Debug code in production | Use structured logging |
| `@suppress` annotations | Hides real issues | Fix the underlying problem |
| Hard-coded URLs/IPs | Environment coupling | Use environment variables or config |

---

## 6. Testing Requirements

> Minimum testing expectations for PRs.

- All new public service methods MUST have unit tests
- State transitions MUST have tests for both happy and error paths
- Payment-related code MUST have tests for edge cases (timeouts, retries, idempotency)
- Tests MUST use factories/fixtures, not production data snapshots
- Test method names describe the scenario: `testCannotFulfillOrderWithoutPayment()`

---

## 7. Migration & Schema Rules

- All schema changes MUST include a migration
- Migrations MUST be reversible (include `down()` method)
- Column renames require a two-phase migration (add new, migrate data, remove old)
- Foreign keys MUST have explicit `ON DELETE` behavior
- New indexes MUST be justified with a query pattern

---

## 8. API Conventions

- REST endpoints follow: `GET /api/v1/orders`, `POST /api/v1/orders`, etc.
- List endpoints return paginated responses with `meta.total`, `meta.page`, `meta.per_page`
- Error responses use: `{"error": {"code": "ORDER_NOT_FOUND", "message": "..."}}`
- All endpoints require authentication except health checks
- Rate limiting: 100 requests/minute for authenticated users

---

## 9. Performance Expectations

- API response time < 200ms for single-resource endpoints
- List endpoints < 500ms with pagination
- Background jobs complete within 5 minutes
- No N+1 queries (use eager loading)
- Database queries per request: maximum 10

---

## 10. Changelog

| Date | Change | Author |
|------|--------|--------|
| 2024-01-15 | Initial constitution | Team Lead |
| 2024-03-01 | Added payment idempotency rule | Backend Lead |
| 2024-06-15 | Added API rate limiting standards | API Team |
