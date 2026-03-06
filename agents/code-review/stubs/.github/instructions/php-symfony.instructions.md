---
name: php-symfony
description: Symfony framework coding standards and patterns context for PHP code review agents
applyWhen: composer.json contains symfony/framework-bundle
---

# Symfony Coding Standards Context

This file provides Symfony-specific context to code review agents. It is automatically applied when `composer.json` contains `symfony/framework-bundle`.

## Framework Version

Target: Symfony 6.x+ with PHP 8.1+. Use PHP 8 attributes (not annotations).

## Doctrine ORM Patterns

### Entity Mapping (PHP 8 Attributes)
```php
// Required pattern
#[ORM\Entity(repositoryClass: OrderRepository::class)]
class Order
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2)]
    private string $amount;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'orders')]
    #[ORM\JoinColumn(nullable: false)]
    private User $user;

    #[ORM\OneToMany(
        targetEntity: OrderItem::class,
        mappedBy: 'order',
        orphanRemoval: true,
        cascade: ['persist', 'remove']
    )]
    private Collection $items;
}
```

### Repository Pattern
- Repositories extend `ServiceEntityRepository`
- Custom query methods return typed results
- Eager loading via `leftJoin()` + `addSelect()`
- Pagination via `setFirstResult()` + `setMaxResults()`
- Bulk updates via DQL `UPDATE` (not loop + flush)

### N+1 Query Prevention
```php
// Flag this pattern
foreach ($orders as $order) {
    $order->getUser()->getName();  // N+1!
}

// Require this pattern
$qb->leftJoin('o.user', 'u')->addSelect('u');
```

### Hydration
- Use `HYDRATE_ARRAY` or `HYDRATE_SCALAR` for read-only reporting
- Use `toIterable()` for batch processing

## Service Container

### Dependency Injection Rules
- Constructor injection only (no setter injection, no service locator)
- Autowiring enabled by default
- Services are private by default
- Use interface typehints when available
- Mark heavyweight services as `lazy: true`

### Forbidden Patterns
- `$container->get('service_name')` - service locator
- `ContainerInterface` injection in application services
- Public service properties

## Controller Rules

### Thin Controllers
- Maximum ~20 lines per action method
- Delegate to services for business logic
- Use typed route attributes: `#[Route('/orders', methods: ['POST'])]`
- Return typed responses: `JsonResponse`, `Response`
- Use `#[IsGranted]` for authorization

### Request Handling
- Deserialize request body to DTOs
- Validate via Symfony Validator on DTOs
- Never access `$request->get()` directly for complex data

## Security

### Authorization
- Use Security Voters for resource-level authorization
- Use `#[IsGranted('ROLE_X')]` attribute on controllers
- Never hard-code role checks in business logic
- All state-changing endpoints require CSRF or API token

### Twig Templates
- Auto-escaping is on by default - never use `|raw` on user input
- Use `{{ form_widget(form._token) }}` for CSRF in forms

## Form Types

- Create dedicated `*Type` classes for all user input
- Validation constraints on DTO/Entity properties
- CSRF protection enabled by default
- Use data transformers for complex conversions

## Event System

- Use `EventSubscriberInterface` or `#[AsEventListener]` for domain events
- Side effects (emails, logs, notifications) via event subscribers
- Events dispatched AFTER primary operation succeeds

## Console Commands

- Use `#[AsCommand]` attribute
- Inject services via constructor
- Return `Command::SUCCESS` or `Command::FAILURE`

## Testing

- Functional tests: `WebTestCase` with `createClient()`
- Integration tests: `KernelTestCase`
- Unit tests: plain PHPUnit `TestCase`
- Database isolation via transactions
- Use `loginUser()` for authenticated requests

## Configuration

- Environment variables via `%env(VAR_NAME)%`
- Service configuration in `config/services.yaml`
- No hardcoded values in source code
- Secrets via Symfony Secrets Vault
