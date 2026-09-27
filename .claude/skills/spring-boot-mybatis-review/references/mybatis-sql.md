# MyBatis and SQL

## Contents
1. Mapper responsibility
2. SQL-first and CTE
3. Parameter binding
4. SQL quality and indexes
5. Dynamic SQL
6. N+1 and batch
7. Pagination
8. Transactions
9. Concurrency
10. Database constraints

## 1. Mapper responsibility

A Mapper does database access only. Called from ServiceImpl, never from Controller.

## 2. SQL-first and CTE

The database does filtering, joining, grouping, aggregation, sorting, counting, ranking, partitioning, pagination and
set operations. Loading thousands of rows into Java to filter/group/sort/aggregate is a finding.

Consider a CTE (`WITH ...`) when Java does "query → loop → group → query → merge → calculate". CTEs fit intermediate
aggregates, ranking, dedup, hierarchies/recursive data and set-based business logic; combine with window functions,
`CASE WHEN`, `GROUP BY`, `JOIN`, subqueries. Do not add a CTE just to look sophisticated.

## 3. Parameter binding

- `#{param}` always for values.
- `${param}` only for dynamic identifiers (column, direction, table) **and only after a whitelist** — an enum or fixed
  map from API value to SQL fragment. `${}` fed by a request parameter is CRITICAL (SQL injection).

```java
public enum OrderSort {
    CREATED_AT_DESC("created_at DESC"), TOTAL_DESC("total_amount DESC");
    private final String sql;
}
```

```xml
ORDER BY ${sort.sql}
```

## 4. SQL quality and indexes

- No `SELECT *`: list columns (also keeps sensitive columns out of responses).
- Check JOIN correctness, duplicate rows, unnecessary `DISTINCT`, needless subqueries, data volume, selected columns.
- Prefer explicit `<resultMap>` for joins/nested results; do not silently rely on `map-underscore-to-camel-case`
  without confirming it is configured.
- Index-friendly predicates — no function on an indexed column:

```sql
-- avoid
WHERE DATE(created_at) = #{date}
-- prefer
WHERE created_at >= #{start}
  AND created_at <  #{end}
```

- Check indexes for `WHERE`, `JOIN`, `ORDER BY`, `GROUP BY`; ask for `EXPLAIN` on queries over large tables.

## 5. Dynamic SQL

Use `<if>`, `<choose>/<when>/<otherwise>`, `<where>`, `<set>`, `<trim>`, `<foreach>`.
Do not build SQL strings in Java when XML expresses it clearly.

## 6. N+1 and batch

Query in a loop is HIGH:

```java
for (User user : users) {
    orderMapper.findByUserId(user.getId());   // N+1
}
```

Fix with `JOIN`, `IN (<foreach>)`, one batch query, CTE, or an aggregate (`GROUP BY order_id` → `COUNT(*)`).

Row-by-row inserts/updates on large datasets: use multi-row `<foreach>` insert, `ExecutorType.BATCH`
(`SqlSessionTemplate` with batch executor), or batch SQL. Evaluate batch size, packet size / max SQL length,
memory and transaction size (chunk commits for huge imports).

## 7. Pagination

- Paginate in the database (`LIMIT/OFFSET` or dialect equivalent) plus a count query when the client needs totals.
- Never load everything and `subList()` — full-table load plus `IndexOutOfBoundsException` on out-of-range pages.
- Validate `page >= 0` and `1 <= size <= MAX_PAGE_SIZE`.
- Large or deep datasets: keyset pagination (`WHERE (created_at, id) < (#{lastCreatedAt}, #{lastId}) ORDER BY ... LIMIT #{size}`).

## 8. Transactions

- `@Transactional` on ServiceImpl public methods, never on Controller.
- Never swallow exceptions inside a transaction; a caught-and-logged exception commits the partial work.
  Let it propagate, or rethrow a business exception.
- Default rollback covers unchecked exceptions only; checked exceptions need `rollbackFor`.
- Self-invocation (`this.otherTransactionalMethod()`) bypasses the proxy.
- `@Transactional(readOnly = true)` for read-only paths when useful.

## 9. Concurrency

Check race conditions, lost updates, duplicate processing, idempotency (retries, double submit).
Prefer atomic SQL over read-modify-write in Java:

```sql
UPDATE product
SET stock = stock - #{quantity}
WHERE product_id = #{id}
  AND stock >= #{quantity}
```

Check the affected-row count; 0 means insufficient stock or concurrent change → throw a business exception.
Alternatives: `SELECT ... FOR UPDATE` inside the transaction, or optimistic locking with a `version` column.

## 10. Database constraints

`PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK` (e.g. `stock >= 0`) — integrity cannot live only in Java.
A unique constraint is the only reliable guard against duplicate inserts under concurrency.
