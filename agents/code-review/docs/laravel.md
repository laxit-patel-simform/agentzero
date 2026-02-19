# Laravel Setup & Usage Guide

How to set up and use the Code Review Agent with Laravel projects.

---

## Quick Start

```bash
# 1. Copy agent files to your Laravel project
cp -r .github/ /path/to/your-laravel-project/.github/

# 2. (Optional) Create project constitution
cp templates/project-constitution.example.md /path/to/your-laravel-project/project-constitution.md

# 3. Use in Copilot
# @workspace /pr-review <PR_NUMBER>
```

The agents auto-detect Laravel from `composer.json` (`laravel/framework`) and apply Laravel-specific checks.

---

## What Gets Checked

### Coding Standards Agent (Laravel Mode)

**Controller Patterns:**
- Thin controllers delegating to Services/Actions
- Form Requests for validation (not inline `$request->validate()` for complex rules)
- API Resources for response transformation
- Proper HTTP status codes (201 for create, 204 for delete)

**Model Patterns:**
- `$fillable` or `$guarded` defined (mass assignment protection)
- `$casts` for type coercion
- Typed relationship methods (`BelongsTo`, `HasMany`)
- Query scopes for reusable conditions

**Authorization:**
- Policies/Gates for resource authorization (not inline role checks)
- `$this->authorize()` in controllers
- `can` middleware on routes
- Rate limiting on sensitive endpoints

**Service Layer:**
- Business logic in `app/Services/` or `app/Actions/`
- Constructor injection (prefer over Facades in services)
- Single responsibility per service

### Linting Agent (Laravel Context)

- Unused model imports
- Missing return types on controller methods
- `env()` called outside config files
- Type mismatches in Eloquent casts vs property types

### Functional Review Agent

When `project-constitution.md` is present, validates against:
- Business rules (state transitions, data integrity)
- Forbidden patterns (debug code, hard-coded values)
- Architecture decisions (service layer, event dispatching)
- Domain vocabulary consistency

### Test Coverage Agent (Laravel Mode)

- `RefreshDatabase` or `DatabaseTransactions` trait usage
- Factory-based test data (`User::factory()->create()`)
- `actingAs()` for authenticated requests
- `assertDatabaseHas()` / `assertDatabaseMissing()` assertions
- Pest test format support (`it()`, `test()`)

---

## Example Findings

### Anti-Patterns the Agents Flag

**N+1 Query (coding-standards, severity: high):**
```php
// Flagged
foreach ($users as $user) {
    echo $user->posts->count();  // Query per user
}

// Recommended
$users = User::with('posts')->get();
// or use withCount
$users = User::withCount('posts')->get();
```

**Mass Assignment Vulnerability (coding-standards, severity: critical):**
```php
// Flagged
$user->update($request->all());

// Expected
$user->update($request->validated());
```

**Business Logic in Controller (coding-standards, severity: medium):**
```php
// Flagged
public function store(Request $request) {
    $amount = $request->input('amount') * 0.9;  // Logic in controller
    Order::create(['amount' => $amount]);
}

// Expected
public function store(StoreOrderRequest $request): JsonResponse {
    $order = $this->orderService->createOrder($request->validated());
    return response()->json(new OrderResource($order), 201);
}
```

**Inline Role Check (functional-review, severity: medium):**
```php
// Flagged
if ($user->is_admin) {
    // Hard-coded role check
}

// Expected
$this->authorize('manage', Order::class);
// or
Gate::allows('manage-orders');
```

**Missing Migration Rollback (test-coverage, severity: high):**
```php
// Flagged - no down() method
class CreateOrdersTable extends Migration {
    public function up() {
        Schema::create('orders', function (Blueprint $table) { ... });
    }
    // Missing down()!
}
```

**Unbounded Query (linting, severity: medium):**
```php
// Flagged
User::all();  // Could return millions of rows

// Expected
User::paginate(15);
// or
User::limit(100)->get();
```

**Missing CSRF (pr-quality, severity: high):**
```html
<!-- Flagged -->
<form method="POST" action="/orders">
    <!-- Missing @csrf -->
</form>
```

**Query in Blade Loop (linting, severity: high):**
```php
// Flagged
@foreach ($orders as $order)
    {{ $order->customer->name }}  {{-- N+1 query per order --}}
@endforeach
```

---

## Laravel-Specific Abort Conditions

The coding-standards agent will abort (return 0% confidence) when:
- Diff contains no `.php` files
- No Laravel-specific patterns found
- Only frontend assets (JS, CSS, Blade-only changes)

It will return reduced confidence (< 50%) when:
- PHP code without Laravel framework usage
- Only configuration or environment changes
- Minimal changes (< 5 lines)

---

## Migration Safety

The agents pay special attention to migrations:

| Check | Severity | What's Flagged |
|-------|----------|---------------|
| Missing `down()` method | high | Migration cannot be rolled back |
| Missing foreign key constraint | medium | `foreignId()` without `constrained()` |
| Missing index on queried column | medium | Foreign keys or frequently filtered columns |
| Raw SQL in `down()` | medium | Non-reversible migration |
| Missing timestamps | low | Table without `timestamps()` |

---

## Customization

### Adding Laravel-Specific Rules

Edit `.github/instructions/php-laravel.instructions.md` to add:
- Custom Eloquent patterns for your project
- Specific middleware conventions
- Queue job patterns and timeout rules
- Notification channel preferences

### Adjusting Severity Levels

In each `.github/agents/*.agent.md` file, modify the severity assignments. For example, if your team requires Pest:

```
// Add to test-coverage agent
**Severity:** medium (using PHPUnit when Pest is available)
```

### Integration with Larastan/PHPStan

The linting agent simulates static analysis checks. For actual static analysis, run Larastan in your CI pipeline alongside the agents. The agents complement (not replace) these tools by catching patterns that static analysis misses (business logic, architecture decisions, test quality).
