# Applications

Each Oracle APEX application lives in its own directory under this folder:

```text
applications/<app-name>/
├── .apex/
│   └── apexlang.json
├── application.apx
├── deployments/
├── page-groups.apx
├── pages/
├── shared-components/
└── supporting-objects/
```

Rules:

- Publish only runtime APEXLang artifacts. Do not copy template docs, `scaffold-example/` containers, or throwaway build output into an app root.
- Keep `.apx` files at LF line endings.
- Read the app's APEX version from `.apex/apexlang.json` before loading any version-specific skill.
- Create the app directory only after the target name and workspace are confirmed.
