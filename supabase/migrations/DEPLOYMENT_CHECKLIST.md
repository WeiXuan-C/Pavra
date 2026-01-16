# Location Tracking Migration - Deployment Checklist

Use this checklist to ensure a smooth deployment of the location tracking feature.

## Pre-Deployment

### Database Preparation
- [ ] **Backup Database**: Create a full database backup before migration
  - Backup method: ________________
  - Backup location: ________________
  - Backup timestamp: ________________

- [ ] **Review Migration File**: Read through `20241203_location_tracking.sql`
  - Reviewer: ________________
  - Review date: ________________
  - Approved: Yes / No

- [ ] **Test in Staging**: Apply migration to staging environment first
  - Staging environment: ________________
  - Applied date: ________________
  - Verification passed: Yes / No

### Team Coordination
- [ ] **Notify Team**: Inform team of upcoming migration
  - Notification sent: ________________
  - Maintenance window: ________________

- [ ] **Assign Roles**:
  - Migration executor: ________________
  - Verification lead: ________________
  - Rollback coordinator: ________________

## Migration Execution

### Apply Migration
- [ ] **Connect to Database**: Establish connection to production database
  - Connection method: CLI / Dashboard / Direct
  - Connected at: ________________

- [ ] **Run Migration**: Execute `20241203_location_tracking.sql`
  - Execution method: ________________
  - Started at: ________________
  - Completed at: ________________
  - Duration: ________________
  - Errors: Yes / No (if yes, document below)

### Verification
- [ ] **Run Verification Script**: Execute `verify_location_tracking_migration.sql`
  - All checks passed: Yes / No
  - Failed checks (if any): ________________

- [ ] **Manual Verification**:
  - [ ] 4 new columns exist in profiles table
  - [ ] Spatial index `idx_profiles_location` created
  - [ ] Function `get_nearby_users` updated
  - [ ] Column comments added
  - [ ] Default values correct

- [ ] **Functional Testing**:
  - [ ] Insert test location data
  - [ ] Query nearby users successfully
  - [ ] Distance calculation accurate
  - [ ] Staleness filter working
  - [ ] Test data cleaned up

## Post-Deployment

### Application Deployment
- [ ] **Deploy Application Code**: Deploy updated app with location tracking features
  - Deployment method: ________________
  - Deployed at: ________________
  - Version: ________________

- [ ] **Verify App Integration**:
  - [ ] LocationTrackingService working
  - [ ] UserApi location methods working
  - [ ] NearbyIssueMonitorService working
  - [ ] UI controls functional

### Monitoring
- [ ] **Enable Monitoring**:
  - [ ] Database query performance monitoring
  - [ ] Application error logging
  - [ ] User adoption tracking

- [ ] **Check Logs** (first 24 hours):
  - [ ] No database errors
  - [ ] No location tracking errors
  - [ ] No notification errors

### Performance
- [ ] **Monitor Query Performance**:
  - [ ] `get_nearby_users` execution time < 200ms
  - [ ] Index being used in query plans
  - [ ] No performance degradation

- [ ] **Monitor Resource Usage**:
  - [ ] Database CPU usage normal
  - [ ] Database memory usage normal
  - [ ] No connection pool issues

### User Communication
- [ ] **Announce Feature**: Inform users about new location tracking feature
  - Announcement method: ________________
  - Announced at: ________________

- [ ] **Update Documentation**:
  - [ ] User guide published
  - [ ] API documentation updated
  - [ ] Help center articles updated

## Rollback Plan (If Needed)

### Rollback Triggers
Rollback if any of the following occur:
- [ ] Migration fails to apply
- [ ] Verification checks fail
- [ ] Critical application errors
- [ ] Severe performance degradation
- [ ] Data corruption detected

### Rollback Execution
- [ ] **Execute Rollback Script**: Run rollback SQL commands
  - Executed by: ________________
  - Executed at: ________________
  - Completed: Yes / No

- [ ] **Restore from Backup** (if needed):
  - Backup restored: ________________
  - Restored at: ________________

- [ ] **Verify Rollback**:
  - [ ] Columns removed
  - [ ] Index removed
  - [ ] Function reverted
  - [ ] Application still functional

- [ ] **Notify Team**: Inform team of rollback
  - Notified at: ________________
  - Reason: ________________

## Sign-Off

### Migration Completion
- **Migration Executor**: ________________
  - Signature: ________________
  - Date: ________________

- **Verification Lead**: ________________
  - Signature: ________________
  - Date: ________________

- **Project Manager**: ________________
  - Signature: ________________
  - Date: ________________

### Notes
Document any issues, observations, or deviations from the plan:

```
[Add notes here]
```

---

## Quick Reference

### Key Files
- Migration: `supabase/migrations/20241203_location_tracking.sql`
- Verification: `supabase/migrations/verify_location_tracking_migration.sql`
- Guide: `supabase/migrations/MIGRATION_GUIDE.md`
- README: `supabase/migrations/README_LOCATION_TRACKING.md`

### Key Commands

**Apply Migration (CLI)**:
```bash
supabase db push
```

**Verify Migration**:
```bash
psql -f supabase/migrations/verify_location_tracking_migration.sql
```

**Rollback**:
```sql
-- See MIGRATION_GUIDE.md for complete rollback script
DROP FUNCTION IF EXISTS public.get_nearby_users(...);
DROP INDEX IF EXISTS public.idx_profiles_location;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS current_latitude, ...;
```

### Support Contacts
- Database Admin: ________________
- Backend Lead: ________________
- DevOps: ________________
- On-Call: ________________

---

**Checklist Version**: 1.0  
**Last Updated**: December 2024
