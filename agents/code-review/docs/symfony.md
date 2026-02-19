# Symfony Setup & Usage Guide

How to set up and use the Code Review Agent with Symfony projects.

---

## Quick Start

```bash
# 1. Copy agent files to your Symfony project
cp -r .github/ /path/to/your-symfony-project/.github/

# 2. (Optional) Create project constitution
cp templates/project-constitution.example.md /path/to/your-symfony-project/project-constitution.md

# 3. Use in Copilot
# @workspace /pr-review <PR_NUMBER>
```

The agents auto-detect Symfony from `composer.json` (`symfony/framework-bundle`) and apply Symfony-specific checks.

---

## What Gets Checked

### Coding Standards Agent (Symfony Mode)

**Service Definition:**
- Constructor injection only (flags `ContainerInterface` injection)
- Autowiring preferred over manual service wiring
- Services are private by default
- Interface typehints used when available

**Controller Patterns:**
- Thin controllers (< 20 lines per action)
- Route attributes: `#[Route('/path', methods: ['GET'])]`
- Typed responses: `JsonResponse`, `Response`
- Authorization via `#[IsGranted]`
- Request deserialization to DTOs

**Repository Pattern:**
- Queries in repositories, not controllers or services
- Eager loading with `leftJoin()` + `addSelect()`
- Parameterized queries (no string concatenation in DQL)
- Pagination on list queries

**Entity Best Practices:**
- PHP 8 attributes for Doctrine mapping (not annotations)
- Typed properties with proper defaults
- `DateTimeImmutable` instead of `DateTime`
- Explicit cascade and orphanRemoval on relationships

**Event System:**
- Event subscribers for side effects
- `#[AsEventListener]` attribute usage
- Events dispatched after primary operation

### Linting Agent (Symfony Context)

- Unused Symfony service imports
- Missing return types on controller actions
- Deprecated Symfony API usage (e.g., `$this->get('service')`)
- Type mismatches in Doctrine entity properties

### Functional Review Agent

When `project-constitution.md` is present, validates against:
- Business rules (state machine transitions, data integrity)
- Forbidden patterns (hard-coded values, debug code)
- Architecture decisions (service layer, repository pattern)
- Domain vocabulary consistency

### Test Coverage Agent (Symfony Mode)

- `WebTestCase` for functional tests
- `KernelTestCase` for integration tests
- Database isolation via transactions
- `loginUser()` for authenticated requests
- Fixture/factory-based test data

---

## Example Findings

### Anti-Patterns the Agents Flag

**N+1 Query (coding-standards, severity: high):**
```php
// Flagged
foreach ($orders as $order) {
    echo $order->getUser()->getName();  // Query per order
}

// Recommended
$orders = $repository->createQueryBuilder('o')
    ->leftJoin('o.user', 'u')
    ->addSelect('u')
    ->getQuery()
    ->getResult();
```

**Business Logic in Repository (coding-standards, severity: medium):**
```php
// Flagged
class OrderRepository extends ServiceEntityRepository {
    public function approveOrder(Order $order) {
        $order->setStatus('approved');
        $this->sendEmail($order);  // Not repository's job
        $this->_em->flush();
    }
}
```

**Missing Security Voter (functional-review, severity: high):**
```php
// Flagged
public function delete(Order $order) {
    if ($order->getAuthor()->getId() === $this->getUser()->getId()) {
        // Manual check instead of voter
    }
}

// Expected
#[IsGranted('delete', 'order')]
public function delete(Order $order): Response { ... }
```

**Raw SQL Without Parameters (linting, severity: critical):**
```php
// Flagged
$sql = "SELECT * FROM orders WHERE user_id = " . $userId;

// Expected
$em->createQuery('SELECT o FROM App\Entity\Order o WHERE o.user = :user')
   ->setParameter('user', $userId);
```

**Missing CSRF Protection (coding-standards, severity: high):**
```php
// Flagged - form without CSRF token
<form method="POST">
    {# Missing {{ form_widget(form._token) }} #}
</form>
```

**Unbounded Query (linting, severity: medium):**
```php
// Flagged
$orders = $repository->findAll();  // Could return millions

// Expected
$orders = $repository->findActivePaginated($page, $limit);
```

---

## Symfony-Specific Abort Conditions

The coding-standards agent will abort (return 0% confidence) when:
- Diff contains no `.php` files
- No Symfony-specific patterns found (no controllers, services, entities)
- Only frontend code (JS, CSS, Twig-only changes)

It will return reduced confidence (< 50%) when:
- PHP code without Symfony framework usage
- Only interface or abstract class definitions
- Minimal changes (< 5 lines)

---

## Customization

### Adding Symfony-Specific Rules

Edit `.github/instructions/php-symfony.instructions.md` to add:
- Custom Doctrine patterns specific to your project
- Bundle-specific conventions
- API Platform resource patterns
- Messenger component patterns

### Adjusting Severity Levels

In each `.github/agents/*.agent.md` file, modify the severity assignments. For example, if your team is strict about thin controllers:

```
// Change from
**Severity:** medium (controller > 30 lines)

// To
**Severity:** high (controller > 20 lines)
```

### Integration with PHPStan/Psalm

The linting agent simulates static analysis checks. For actual static analysis, run PHPStan/Psalm in your CI pipeline alongside the agents. The agents complement (not replace) these tools by catching patterns that static analysis misses (business logic, architecture decisions).
