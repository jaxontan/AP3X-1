# Domain Model: <Domain>

- Status: draft | reviewed | approved
- Related specification: <link/path>
- Target schema: <schema>

## 1. Entities

### <Entity>

- **Meaning:** <business noun and why it exists>
- **Identity:** <natural key> / <surrogate key>
- **Lifecycle:** <states and transitions>
- **Aggregate root:** yes/no
- **Owner:** <business owner>

| Attribute | Type | Required | Meaning | Rule |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | BR-... |

## 2. Relationships

| From | To | Cardinality | Optional | Delete behavior | Notes |
| --- | --- | --- | --- | --- | --- |
| ... | ... | 1:N | no | restrict | ... |

## 3. Invariants

| ID | Invariant | Enforcement | Test |
| --- | --- | --- | --- |
| INV-... | ... | constraint/package | ... |

## 4. State model

```text
DRAFT -> SUBMITTED -> APPROVED -> CLOSED
             |            |
             v            v
          REJECTED      CANCELLED
```

| From | To | Actor | Guard | Side effects | Audit |
| --- | --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... | ... |

## 5. Reference data

| Set | Values | Effective dating | Owner |
| --- | --- | --- | --- |
| ... | ... | yes/no | ... |

## 6. Audit and retention

- Audit columns:
- Business audit table:
- Retention:
- Archive/purge:
- Legal hold:

## 7. Open questions

| Question | Default assumption | Impact |
| --- | --- | --- |
| ... | ... | ... |
