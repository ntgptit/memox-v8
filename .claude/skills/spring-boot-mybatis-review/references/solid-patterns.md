# SOLID and design patterns — when they earn their place

Principle: KISS + SOLID when needed + composition over inheritance + explicit over clever + convention over custom
abstraction + SQL-first + simple layered architecture. Never apply a principle to the extreme:

- SRP ≠ one method per class.
- OCP ≠ an interface for every piece of logic.
- DIP ≠ wrapping every Mapper in a Repository.
- Patterns ≠ more is better. "Has an interface = good, no interface = bad" is not a review argument.

## SOLID review questions

| Principle | Ask | Finding when | Not a finding |
|---|---|---|---|
| SRP | Does the class have several independent reasons to change? | `UserServiceImpl` also validates, generates Excel, sends email, parses CSV, calls external API → split into `NotificationService`, `CsvImportService`, `PaymentCalculator`… | A long method with one responsibility; splitting a few lines into a new class |
| OCP | Does every new type require editing a big `if/switch`? | Growing chain where each branch has distinct behaviour → Strategy | 2 simple cases with no sign of growth |
| LSP | Does an implementation break the contract? | One impl returns `null`, another throws `UnsupportedOperationException` for a method all callers rely on; `Square extends Rectangle` with setters | — prefer composition when it is not truly *is-a* |
| ISP | Do clients depend on methods they do not use? | `CommonService` with `createUser`, `processPayment`, `sendEmail`, `exportCsv`… | A focused `UserService` with several user methods |
| DIP | Does business logic depend on a concrete low-level class? | Service depends on `StripePaymentGateway` while several gateways exist or vendor isolation is needed → `PaymentGateway` | `private final UserMapper userMapper;` — correct as is |

## Pattern catalogue

| Pattern | Use when | Do not use when |
|---|---|---|
| Strategy | Several algorithms by type, new types expected, `if/switch` growing. `interface DiscountStrategy { DiscountType supports(); BigDecimal calculate(Order o); }` injected as `Map<DiscountType, DiscountStrategy>` | `if (active)`; two stable branches |
| Factory | Complex creation or type → implementation selection (`paymentProcessorFactory.get(type)`) | `UserFactory` replacing `new User()` |
| Builder | Many fields / many optional fields; Lombok `@Builder` | Two simple fields where a constructor is clearer |
| Template Method | Several flows share Validate → Load → Process → Save → Log with a few differing steps | Reusing 2–3 lines; deep inheritance — prefer composition |
| Adapter | External API / third-party SDK / legacy / multiple vendors; keeps SDK types out of business code (`PaymentGateway` ← `StripeAdapter`) | Internal code with a compatible interface |
| Facade | One use case coordinates several subsystems and callers must not know the details | Wrapping `userService.getUser()`; ServiceImpl already orchestrates |
| Decorator | Add behaviour without touching the implementation | Cross-cutting concerns Spring already handles — prefer AOP, interceptor, filter |
| Observer / Event | One event, several independent side effects (email, analytics, audit) via `ApplicationEventPublisher` or messaging | Caller needs an immediate result, strong transactional coupling, or synchronous error propagation; flow becomes untraceable |
| Chain of Responsibility | Ordered, independent, pluggable steps (validation → permission → business → fraud) | Fixed, very simple flow |
| Specification | Complex composable business rules in pure Java | Database filtering — use SQL / CTE / dynamic SQL |
| State | Behaviour and transitions vary strongly by state (CREATED → PAID → SHIPPED → CANCELLED) | A few `if (status != PAID)` checks |
| Command | Queue, retry, undo, audit, job execution, dispatch | Turning `service.createUser(request)` into several classes |
| Singleton | Never hand-rolled (`private static INSTANCE`) — Spring beans are singletons | — |
| Repository | A real data abstraction beyond the Mapper | Forwarding `userMapper.findById(id)` 1:1 — use the Mapper from ServiceImpl |
| Object mapping | MapStruct for large, repeated mappings | Trivial mapping — a `builder()` is enough |
| DI | Constructor injection | Service locator `ApplicationContext.getBean(...)`, static dependencies |

## Warning signs that justify looking at a pattern

Large `if/switch` by type · duplicated logic across implementations · complex `new` in many places · third-party SDK
spreading into business code · class with many responsibilities · interchangeable algorithms · several independent
handlers · increasingly complex state transitions.

Do **not** propose a pattern when the code is short, clear, rarely changed, not duplicated and under no extension pressure.

## Overengineering anti-pattern

```
userMapper.findById(id)
```

must not become `UserQuery → UserQueryHandler → UserQueryFactory → UserRepository → UserRepositoryImpl → UserDataSource → UserMapper`.

Decision rule: Problem → change pressure → current complexity → fitting pattern? → does it make the code simpler?
If not, keep the current code. A good pattern makes code easier to understand, change and test, with less duplication
and coupling; a bad one only adds classes, interfaces and indirection.
