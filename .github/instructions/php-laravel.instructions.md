---
name: php-laravel
description: Laravel framework coding standards and patterns context for PHP code review agents
applyWhen: composer.json contains laravel/framework
---

# Laravel Coding Standards Context

This file provides Laravel-specific context to code review agents. It is automatically applied when `composer.json` contains `laravel/framework`.

## Framework Version

Target: Laravel 10+ with PHP 8.1+.

## Eloquent ORM Patterns

### Model Definition
```php
// Required pattern
class Order extends Model
{
    protected $fillable = ['user_id', 'amount', 'status'];

    protected $casts = [
        'amount' => 'decimal:2',
        'shipped_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
```

### Eager Loading
```php
// Flag this pattern (N+1)
foreach ($orders as $order) {
    $order->user->name;  // N+1!
}

// Require this pattern
$orders = Order::with('user')->get();
// or
$orders = Order::with(['user', 'items'])->get();
```

### Query Patterns
- Use query scopes for reusable conditions
- Use `paginate()` or `limit()` on large datasets (never `all()` unbounded)
- Use `whereIn()` for bulk operations (not loops)
- Use `cursor()` or `lazy()` for memory-efficient large exports
- Use `chunk()` for batch processing

### Mass Assignment Protection
- Always define `$fillable` or `$guarded` on models
- Use `$request->validated()` not `$request->all()` for mass assignment
- Never use `Model::unguard()` in production code

## Controller Rules

### Thin Controllers
- Maximum ~20 lines per action method
- Use Form Requests for validation (not inline `$request->validate()` for complex rules)
- Return API Resources for JSON responses
- Delegate business logic to Service classes

### Request Handling
```php
// Required pattern
public function store(StoreOrderRequest $request): JsonResponse
{
    $order = $this->orderService->createOrder($request->validated());
    return response()->json(new OrderResource($order), 201);
}
```

## Authorization

### Policies and Gates
- Use Policies for resource-level authorization
- Use `$this->authorize()` or `Gate::allows()` in controllers
- Never hard-code role checks: `if ($user->is_admin)` is forbidden
- Use `can` middleware on routes

### Middleware
- Authentication: `auth` middleware on protected routes
- Rate limiting: `throttle` middleware on sensitive endpoints
- CORS: configured in `config/cors.php`

## Blade Templates

### Security
- `{{ $var }}` auto-escapes output (safe by default)
- `{!! $var !!}` is unescaped - flag if used with user input
- Always include `@csrf` in forms
- Use `@method('PUT')` / `@method('DELETE')` for form method spoofing

### Performance
- Avoid queries inside `@foreach` loops
- Pre-load all data in controllers
- Use `@forelse` for empty state handling

## Queue Jobs

- Long operations MUST be dispatched to queues
- Jobs should implement `ShouldQueue`
- Set `$timeout` and `$tries` properties
- Use `$this->release()` for retry with backoff
- Batch operations with `Bus::batch()`

## Events and Listeners

- Domain events for side effects (emails, notifications, audit logs)
- Use `ShouldQueue` on listeners for async processing
- Events dispatched AFTER primary operation

## Migrations

### Safety Rules
- Always implement `down()` method for rollback
- Foreign keys MUST have `constrained()` with `onDelete()` behavior
- Index frequently queried columns
- Column renames: two-phase migration (add, migrate data, drop)
- No raw SQL in `down()` - keep migrations reversible

### Required Pattern
```php
public function up(): void
{
    Schema::create('orders', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->decimal('amount', 10, 2);
        $table->string('status')->default('draft');
        $table->index(['user_id', 'status']);
        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('orders');
}
```

## Service Layer

- Business logic in `app/Services/` or `app/Actions/`
- Services injected via constructor (not Facades in service classes)
- Single responsibility per service/action
- Domain exceptions for business rule violations

## Testing

### Conventions
- Feature tests: `tests/Feature/` with HTTP assertions
- Unit tests: `tests/Unit/` with pure logic tests
- Use `RefreshDatabase` or `DatabaseTransactions` trait
- Factory-based test data: `User::factory()->create()`
- Authentication: `$this->actingAs($user)`
- Database assertions: `assertDatabaseHas()`, `assertDatabaseMissing()`

### Pest Support
```php
it('creates an order successfully', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)
        ->postJson('/api/orders', ['amount' => 100]);

    $response->assertStatus(201);
    $this->assertDatabaseHas('orders', ['user_id' => $user->id]);
});
```

## Configuration

- Environment variables via `config()` helper (never `env()` outside config files)
- Config caching: `php artisan config:cache`
- No hardcoded values in source code
- Secrets in `.env` (never committed)

## Error Handling

- Custom exceptions in `app/Exceptions/`
- Exception rendering in `Handler.php` or via `render()` method
- API errors return consistent JSON format
- Never expose stack traces in production
