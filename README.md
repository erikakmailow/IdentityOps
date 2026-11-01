# IdentityOps

IdentityOps is a PowerShell-based identity lifecycle automation project for employee onboarding, offboarding, HR data validation, access-profile comparison, password generation, and approval safeguards.

## Project status

**Development and preview only.**

The current modules and tests cover local validation and preview behavior. Active Directory and Microsoft Entra ID components are prerequisite checks and connection scaffolding. ADP and Oracle components currently provide HR field mapping and import scaffolding, not complete live integrations.

Passing local tests does not establish production readiness.

## Requirements

- Windows PowerShell 5.1 or later
- Windows for the current provider prerequisites
- Additional modules and permissions for future live integrations

## Start the menu

From the project root:

```powershell
.\IdentityOps.ps1
```

## Run all tests

```powershell
.\tests\Run-AllTests.ps1
```

The current test runner covers:

- Access-profile comparison
- Onboarding and offboarding lifecycle previews
- Approval-gate safeguards
- HR batch validation and duplicate detection
- Password-generator policies

## Project structure

```text
IdentityOps/
  config/
  src/
    Core/
    Passwords/
    Onboarding/
    Offboarding/
    Access/
    Providers/
      ActiveDirectory/
      EntraID/
      ADP/
      Oracle/
  tests/
  logs/
  reports/
  docs/
  IdentityOps.ps1
  README.md
```

## Safety controls

- Development configuration keeps dry-run enabled.
- Production changes are disabled by default.
- Invalid employee records should be rejected.
- Duplicate employee IDs should block affected records.
- Privileged groups are excluded from ordinary access proposals.
- Approval-gate evaluation does not itself authorize execution.
- Provider scaffolding must not be treated as a completed integration.

## Security notes

- Use fictional data for local tests.
- Do not commit real employee records, credentials, access tokens, or generated passwords.
- Treat generated passwords as secrets.
- Basic log redaction does not replace safe handling of sensitive data.
- Live identity changes require least-privilege access, independently enforced authorization and approval, auditability, and testing in a dedicated environment.

## License

No license has been selected yet. Choose a license before distributing the project.
