# Security Policy

Thank you for helping keep Supabase Vault and its users safe.

## Reporting a vulnerability

Please report suspected vulnerabilities through our HackerOne program:
<https://hackerone.com/supabase>. Please do not open public GitHub issues or
pull requests for security problems.

This repository contains Supabase Vault (`supabase_vault`), a Postgres
extension for storing secrets encrypted in the database. It is available on
the hosted Supabase platform and can be installed in any Postgres. We accept
reports for both, and we triage them differently (see "Hosted vs. standalone"
below).

## What we consider a vulnerability

In general, we want to hear about anything that lets a database role use
Vault to gain privileges it was not granted, or to read secrets it was not
given access to. The problem should be present on the hosted platform or in
a default install.

Examples of what this includes (these are illustrations, not a complete list):

- **Privilege escalation through Vault's objects.** Using Vault's functions,
  tables or the grants its install script creates to reach superuser or
  another privileged role.
- **Installable versions that lead to escalation.** On the hosted platform, an
  extension version that a customer role is allowed to install and that leads
  to escalation is in scope, even if a newer version fixed the problem.

## What we do not consider a vulnerability

Reports that rely on the behavior below will normally be closed as
informative or not applicable.

**Prerequisites that make the attack pointless**

- The attacker already holds superuser, or a role that has been granted access
  to the secrets they read.
- The attacker needs grants that neither Vault's install nor the hosted
  platform gives, without showing that something grants them.

## Out of scope for every Supabase asset

These are excluded program-wide (see also
<https://supabase.com/.well-known/security.txt>). They are repeated here so
you do not need to leave this repository to find them.

- Clickjacking on pages with no sensitive actions.
- Unauthenticated, logout and login CSRF.
- Attacks requiring MITM or physical access to a user's device.
- Attacks requiring social engineering.
- Any activity that could lead to the disruption of our service (DoS).
  This means volumetric attacks, load testing and flooding. A vulnerability in
  our code that lets an unprivileged attacker crash a service or exhaust
  resources for other users or tenants is in scope. Denial of service that only
  affects the attacker's own project, or that needs admin or owner privileges,
  is not.
- Content spoofing and text injection issues without showing an attack vector,
  or without being able to modify HTML/CSS.
- Email spoofing.
- Missing DNSSEC, CAA or CSP headers.
- Lack of Secure or HttpOnly flags on non-sensitive cookies.
- Dead links.
- User enumeration.

## Hosted vs. standalone

On the hosted platform, customer roles can install extensions that would
normally need superuser, and Supabase reserves superuser for itself. A problem
can therefore exist on the hosted platform and not on a default standalone
install, or the other way around. Say which one you tested. If you can, test
both: whether a default standalone install is affected decides whether other
users of the extension need to be told.

## How to write a report that gets triaged quickly

- **Say what you tested, at the top of the report and in the title.** Use one of
  these labels, for example `[Production] ...` in the title and a "Target" line
  at the start of the description:
  - **Production**: the hosted Supabase platform, against a project you own.
    Include the project ref and the role you connected as. Never test another
    customer's project.
  - **Standalone, default configuration**: Vault from this repository,
    installed as the README describes, with no extra grants. Include the Vault
    and Postgres versions.
  - **Custom configuration**: you changed grants, settings or code. List every
    change and why. We triage these lower.

  Reports that do not say which of the three they are about are slower to
  triage, and are often closed with a request to retest. A finding that works
  only on a custom configuration is not a finding against production.

- **Give a short, runnable PoC.** The exact SQL, including any `CREATE
  EXTENSION ... VERSION` you ran, run as the role you name, and output showing
  what you gained.
- **State the attacker's starting position and the boundary you crossed.**
- **Include versions.** The Vault version, the Postgres version, and related
  extensions.
- **One issue per report.** Link variants of the same root cause instead of
  filing each variant separately.
- **Do not send unreviewed AI output.** Reports that were not reproduced by a
  human and that ignore the documentation are closed. AI-assisted analysis is
  fine when you have verified the result.
- **Respond to follow-up questions.** Reports that go quiet after we ask for a
  reproduction are closed.

## Severity

We rate severity by realistic impact. Reaching superuser on the hosted
platform is valid, but is usually rated lower than its raw description
suggests, because the rating follows what it leads to. Escaping to the host or
to another project is rated higher.

## Testing and disclosure

These are our program-wide rules. They also apply to AI agents and automated
tools acting on your behalf.

**Testing**

- Do not run automated scanners against other customers' projects. Scanners can
  run up costs for our users, can disrupt services, and our own security
  systems cannot tell hostile reconnaissance from research. If you want to run
  an automated scanner, notify security@supabase.com first and run it only on
  your own Supabase project.
- Do not attack projects that belong to other customers.
- Do not take advantage of a vulnerability you find, for example by downloading
  more data than necessary to demonstrate it, or by deleting or modifying other
  people's data.

**Disclosure**

- Do not reveal the problem to others until we have researched and fixed it and
  informed affected customers.
- If you want to share your research publicly (a conference, a blog or any
  other public forum), send us a draft for review and approval at least 30 days
  before the publication date. Do not include data about Supabase customer
  projects, customers' data, or information about Supabase employees,
  contractors or partners.

**What we promise**

- We will respond to your report within 5 business days with our evaluation and
  an expected resolution date.
- If you have followed these instructions, we will not take legal action against
  you in regard to the report.
- We will handle your report with strict confidentiality and will not pass on
  your personal details to third parties without your permission.
- We will keep you informed of our progress.
- In public information about the problem, we will name you as the discoverer
  unless you prefer otherwise.
