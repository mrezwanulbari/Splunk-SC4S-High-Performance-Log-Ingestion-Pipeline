# Source Onboarding: Palo Alto Networks Firewall

Reference onboarding steps for ingesting Palo Alto Networks firewall logs through SC4S, including the sourcetype mapping and common pitfalls.

## Firewall-Side Configuration

1. Palo Alto Panorama/firewall → **Device > Server Profiles > Syslog** → add a new syslog server profile pointing to the SC4S listener IP, port 514 (UDP) or 6514 (TLS — preferred)
2. Set format to **BSD** (SC4S's Palo Alto parser expects standard BSD syslog framing)
3. Under **Log Settings**, enable forwarding for: Traffic, Threat, System, Config, and HIP Match logs (URL Filtering optional, high volume)

## SC4S-Side Recognition

SC4S auto-detects Palo Alto's syslog format via its built-in `paloalto` app and routes to the appropriate sourcetype automatically — no manual parsing configuration needed for standard log types:

| Palo Alto Log Type | Splunk Sourcetype |
|---|---|
| Traffic | `pan:traffic` |
| Threat | `pan:threat` |
| System | `pan:system` |
| Config | `pan:config` |

## Common Pitfalls

- **Log volume underestimation:** Traffic logs from a busy perimeter firewall can be 5-10x the volume teams initially estimate. Size your indexer capacity and license against Threat + System first, add Traffic logs with headroom, not as an afterthought.
- **Time zone mismatch:** Palo Alto devices default to local device time in some log formats. Verify `_time` extraction matches actual event time — a silent timezone offset makes correlation searches with other sources subtly wrong rather than obviously broken.
- **Duplicate ingestion:** If both Panorama and individual firewalls are configured to forward the same logs, you'll double-ingest. Forward from Panorama only, or from firewalls only — not both.

---
*Part of the [Splunk-SC4S-High-Performance-Log-Ingestion-Pipeline](../README.md) repository.*
