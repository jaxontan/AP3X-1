# Page Map: <Application>

- Target APEX version: 26.1 | 26.2
- Application ID: <id or NEW>
- Authentication: <scheme>
- Home page: <page number>

## 1. Roles and authorization

| Role | Authorization scheme | Data scope | Landing page |
| --- | --- | --- | --- |
| ... | ... | own/team/all | ... |

## 2. Pages

### Page <number>: <name>

- **Purpose:** <actor goal in one sentence>
- **Authorization:** <scheme>
- **Entry points:** <navigation/link/modal>
- **Primary action:** <action>
- **Empty state:** <message and next step>
- **Error state:** <message and recovery>

| Region | Type | Source | Notes |
| --- | --- | --- | --- |
| ... | ... | ... | ... |

| Item | Type | Source | Required | Rule |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | BR-... |

| Button | Action | Server-side condition | Confirmation |
| --- | --- | --- | --- |
| ... | ... | ... | ... |

| Process | Type | PL/SQL operation | Sequence |
| --- | --- | --- | --- |
| ... | ... | `package.operation` | ... |

| Validation | Rule | Message | Item |
| --- | --- | --- | --- |
| ... | BR-... | ... | ... |

| Branch | Condition | Target |
| --- | --- | --- |
| ... | ... | ... |

## 3. Navigation

```text
Home
├── <List page>
│   └── <Detail/Form>
├── <Approval queue>
└── Administration
    └── <Reference data>
```

## 4. Shared components

- Authentication:
- Authorization schemes:
- LOVs:
- Lists:
- Templates:
- Build options:
- Static files:

## 5. Performance and accessibility

- Largest report and expected rows:
- Indexes required:
- Pagination strategy:
- Lazy-loaded regions:
- Keyboard path:
- Labels and error messages:
- Contrast and responsive behavior:

## 6. Deployment

- Supporting objects:
- Seed data:
- Environment substitutions:
- Rollback plan:
- Post-deployment checks:
