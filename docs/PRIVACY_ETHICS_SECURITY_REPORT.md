# Project 17 Privacy, Ethics, and Data Security Report

## Project

Gender-Sensitive Safety Incident Reporting Platform for Women in Public Spaces.

## Purpose

This report defines how the platform protects reporters while collecting useful safety intelligence for city council, TAWLA, police partners, NGOs, and researchers. The system is designed to collect the minimum information needed to understand incident patterns by category, time, location type, and approximate geography.

## Data Collected

The mobile reporting flow collects:

- Incident category.
- Location type.
- Incident date and time.
- GPS coordinates captured by the device.
- Optional approximate area name.
- Optional ward or district.
- Optional free-text description.
- Consent acknowledgement.
- Language code.

The public incident report does not require the reporter's name, phone number, national identity number, exact address, or contact details.

## Anonymity Controls

The reporting feature is treated as anonymous by default:

- Reports use a generated public reference instead of a reporter identity.
- The backend report table has no foreign key to the mobile user account.
- Optional descriptions should not request names, phone numbers, or direct identifiers.
- Admin users review reports through references, categories, time, and location context instead of personal profiles.

## Consent and Transparency

The app requires consent acknowledgement before submission. The consent message should explain:

- The report will be used for safety analysis and response planning.
- GPS location will be collected for hotspot mapping.
- The platform should not be used for emergency dispatch.
- Users should avoid including personally identifying information in descriptions.
- Approved reports may contribute to aggregate maps and monthly policy briefs.

## Safety and Harm Reduction

The system handles sensitive gender-based safety information and should reduce risk to reporters:

- The app stores offline pending reports locally only until they can sync.
- Admin views should be limited to authorized staff.
- Public outputs should use aggregate statistics wherever possible.
- Monthly briefs should avoid publishing exact coordinates for individual incidents.
- Descriptions should be moderated before any sharing outside the admin portal.

## Location Privacy

GPS coordinates are useful for hotspot mapping but can expose risk when combined with timestamps and descriptions. Recommended safeguards:

- Show precise points only inside the protected admin portal.
- Use aggregated areas, clusters, or heatmaps for policy audiences.
- Do not publish individual coordinates in public reports.
- Consider rounding or geohashing coordinates for exported datasets.
- Allow moderators to suppress records that are too identifying.

## Access Control

Portal access should be restricted to staff users only. Role guidance:

- Moderator: review, approve, reject, and archive reports.
- Analyst: view approved data, maps, and monthly brief outputs.
- Supervisor: manage quality, audit decisions, and approve external sharing.

Every production deployment should use named admin accounts instead of shared passwords.

## Data Quality and Moderation

Moderation is required before incidents feed the hotspot map or policy brief. Moderators should check:

- Whether the category and location type are reasonable.
- Whether the description contains personal identifiers.
- Whether the report looks duplicated.
- Whether the location is usable but not unnecessarily revealing.
- Whether the report should be approved, rejected, archived, or marked under review.

## Security Requirements

Before production use:

- Set `DEBUG=False`.
- Move secrets and database credentials into environment variables.
- Use HTTPS for the backend.
- Restrict `ALLOWED_HOSTS` to approved domains or IPs.
- Use strong staff passwords and rotate credentials.
- Back up the Postgres/PostGIS database.
- Keep Django, Flutter, and dependency packages updated.
- Enable server logs for admin actions, authentication, and export activity.

## Retention

A recommended retention policy:

- Pending offline reports: delete from the device after successful sync.
- Rejected reports: retain only as long as needed for audit and quality review.
- Approved reports: retain for trend analysis, but review annually.
- Exported briefs: store final approved versions with month, audience, and generation date.

## Ethical Use

The platform should support infrastructure and enforcement decisions without exposing survivors or reporters. Data should not be used to blame victims, identify reporters, target communities unfairly, or publish exact incident trails. Policy outputs should focus on safer lighting, transport safety, patrol timing, community outreach, and survivor-centered support.

## Final Production Checklist

- Consent wording reviewed by project supervisor.
- Privacy warning visible in the app before submission.
- Staff-only portal verified.
- Sample reports checked for accidental identifiers.
- Exported brief reviewed before sharing.
- Database backup and credential plan documented.
- Emergency disclaimer included in app copy.
- Contact/support pathway confirmed with TAWLA or another approved partner.