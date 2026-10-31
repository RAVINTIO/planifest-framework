---
title: "Backlog Entry: 0000356 - decide which compliance frameworks Framework enforces by default"
summary: "A proposed default-or-option decision for GAMP 5, ISO 27001, GCAP, NIST, and OWASP, plus the other frameworks to assess."
status: "open"
---
# Backlog Entry: 0000356 - decide which compliance frameworks Framework enforces by default

**Source feature:** none (human request)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline, as the first decision inside 0000348
**Related:** 0000279, 0000285, 0000287, 0000288, 0000337, 0000348, 0000357

---

## Context

On 2026-10-31 the owner asked that Framework consider GAMP 5, ISO 27001, the UK Government Cyber Action Plan (GCAP), NIST, and OWASP. For each one, Framework must decide whether it enforces the framework by default or offers it as an option. The owner also asked for a list of the other frameworks to consider.

This entry records a proposal. The owner hasn't confirmed it yet.

## Principle

- **Enforce by default** when a control costs little, applies to all software, and only adds good practice. A team can tighten a default through `ravintio-overrides/`. A team can loosen one only through a waiver (0000287).
- **Offer as an option** when a framework adds heavy ceremony, binds only one sector or buyer, or certifies an organisation rather than software. The option is a compliance profile under 0000348, chosen at P0 and locked by 0000288.
- **Trigger automatically** when a design feature makes a framework apply, such as an LLM in the product.

Framework records evidence and never claims compliance, as 0000279 says.

## Proposed decision

| Framework | Default | Option or trigger | Reason |
|---|---|---|---|
| OWASP Top 10 and ASVS Level 1 | Enforce. P1 adds criteria and P5 checks them. | ASVS Level 2 or 3 is an option, tied to risk class (0000339). | Universal, cheap, and already close to the P5 STRIDE review. |
| OWASP Top 10 for LLM Applications | None | Trigger when the design embeds an LLM (0000347). | Applies only to AI products. |
| OWASP MASVS | None | Trigger for mobile apps. | Applies only to mobile. |
| OWASP SAMM | None | Out of scope | It measures an organisation's maturity, not one feature. |
| NIST SSDF (SP 800-218) core practices | Enforce the practices Framework can evidence, such as PW and PS and part of RV. | SLSA level and a secure software attestation are options. | Most practices come with the base pipeline (0000280 to 0000290). |
| NIST SP 800-218A | None | Trigger with an LLM in the product. | The SSDF profile for generative AI. |
| NIST SP 800-53, SP 800-171, and FedRAMP | None | Option for US federal and defence buyers. | Sector-bound and heavy. |
| NIST CSF 2.0 | None | Out of scope | Organisation-level. |
| ISO 27001 Annex A 8.25 to 8.33 | None, because the SSDF default covers most of it | Option: an Annex A mapping profile. | Certifies an organisation's ISMS, not software. |
| ISO 27001 data sent to the model provider | Enforce (0000357). | None | Every customer's auditor asks this first. |
| GAMP 5 | Enforce its general base controls: attributable approvals (0000286), audit trail (0000289), and traceability (0000340). | Option: the GxP profile (0000337) adds categories, the specification hierarchy, validation plan, and summary report. | The base controls help every regulated buyer. The rest is GxP ceremony. |
| UK GCAP | None | Option: a UK public sector profile. It bundles the Software Security Code of Practice, Secure by Design, and the Cyber Assessment Framework. | The code of practice is voluntary. Binding duties come through the Cyber Security and Resilience Bill, which was still a bill in January 2026. The SSDF default covers most of the code's software principles. |

Check the GCAP position against the plan and Bill text at pickup.

## Other frameworks to assess

Each needs the same default-or-option call.

**EU and UK regulation**

- EU Cyber Resilience Act: vulnerability handling, SBOM, and security updates for products with digital elements.
- NIS2 and DORA: supply chain and ICT third-party risk for essential entities and financial services.
- EU AI Act and ISO/IEC 42001: AI management, mostly when the product is an AI system.
- GDPR and UK GDPR Article 25: data protection by design.
- UK Cyber Essentials and Cyber Essentials Plus: the UK government supplier baseline.

**Life sciences and medical devices**

- IEC 81001-5-1: the security lifecycle for health software, which pairs with IEC 62304.
- FDA premarket cybersecurity guidance (section 524B): SBOM and threat modelling for devices.
- EU GMP Annex 11 revision and draft Annex 22 (AI): check their status at pickup.

**Finance and payments**

- PCI DSS v4.0 requirement 6: secure software for payment systems.
- SOC 2 Trust Services Criteria: common for SaaS buyers.

**Industrial and automotive**

- IEC 62443-4-1: the secure development lifecycle for industrial systems, relevant to pharmaceutical manufacturing.
- ISO/SAE 21434 and UNECE R155: automotive. 0000348 judged automotive safety not worth targeting, but security may differ.

**US government and supply chain**

- CMMC 2.0: US defence suppliers, built on SP 800-171.
- CISA Secure by Design and the secure software self-attestation form.
- SBOM formats (SPDX, CycloneDX), OpenSSF Scorecard, and OpenChain (ISO/IEC 5230 and 18974).
- CIS Controls v8 control 16: application software security.

## Wanted outcome

- The owner confirms or changes each row of the decision table.
- 0000348 ships a profile skeleton for each option and a default set for each enforced row.
- Each framework under "Other frameworks to assess" gets a default, option, trigger, or out-of-scope call.

## Open questions

- Should the regulated base controls be on for every install, or only when a team picks any regulated profile?
- Should the UK public sector profile include Cyber Essentials, which certifies an organisation?

## Why Deferred

The owner asked for it on 2026-10-31. The decision needs the owner's confirmation and belongs inside the 0000348 design.
