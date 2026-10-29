# Application Page Design & Requirements

<!--
Owned by YOU. Describe what you want: purpose, roles, pages, fields, rules, and the look.
The agent never edits this file. It reads it, writes its technical plan to
working/page-design/application-design.md, and waits for your approval before building.
-->

## 1. Overview & Business Intent
- **Application Name**: [e.g. Customer Portal / Inventory Tracker]
- **Target Audience & Roles**: [e.g. Staff, Manager, Administrator]
- **Core Purpose**: [What problem does this application solve?]
- **Design & Theme Direction** (optional; you are not limited to the stock Universal Theme look):
  - **Brand colours**: [e.g. primary `#7C3AED`, accent `#A855F7`, or "use stock theme"]
  - **Visual tone**: [e.g. modern and playful / calm enterprise / premium editorial]
  - **Shape & depth**: [e.g. 12px rounded corners, soft card shadows, pill-shaped status badges]
  - **Typography**: [e.g. Inter for UI, tabular numbers in reports]
  - **Icons & imagery**: [e.g. Font APEX icons per category: plane, receipt, wallet]
  - **Signature element**: [one thing that should make this app feel distinctive]
  - **Dark mode**: [required / not required]

---

## 2. Page Map & Layout Design

### Page 1: Home / Dashboard
- **Page Type**: Normal Page
- **Authorization**: Public / Authenticated
- **Regions & Components**:
  - Summary metrics or navigation cards
  - Quick-start action links

### Page 10: [Main Report / Queue]
- **Page Type**: Interactive Report / Classic Report
- **Authorization**: [e.g. Staff or Manager]
- **Regions & Components**:
  - Report table showing key records
  - Filter items or search bar
- **Buttons & Actions**:
  - "Create New" button redirecting to Page 11

### Page 11: [Entry Form / Details Dialog]
- **Page Type**: Modal Dialog Form
- **Authorization**: [e.g. Staff]
- **Form Fields / Page Items**:
  - [Field 1: Name, Type, Required/Optional]
  - [Field 2: Amount / Category LOV]
- **Buttons & Processes**:
  - "Cancel" button (close dialog)
  - "Submit" / "Save" button (triggers database package call)

---

## 3. Business Rules & Validations
- **Rule 1**: [e.g. Fields A and B are mandatory before submission]
- **Rule 2**: [e.g. Approval threshold or state transition rules]
- **Rule 3**: [e.g. Rejections require a mandatory explanation]
