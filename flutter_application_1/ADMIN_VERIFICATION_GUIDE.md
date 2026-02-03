# Administrator Guide: Employer Verification Process

## Overview
This guide explains how to verify employer accounts in the Tiro Mo Mangaung job seeker app. Employer verification is a manual process performed by administrators through the Firebase Firestore console.

---

## Verification Process

### Step 1: Access Firebase Firestore Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **Tiro Mo Mangaung** (or your project name)
3. Click on **Firestore Database** in the left sidebar
4. You'll see the Firestore collections

### Step 2: Navigate to the Users Collection

1. Click on the **`users`** collection
2. You'll see a list of all users (both job seekers and employers)
3. Look for users where:
   - `userType` field = `"employer"`
   - `verificationStatus` field = `"pending"`

### Step 3: Review Employer Information

Before verifying, review the employer's information:

**Required Fields to Check:**
- ✅ **`companyName`**: Is it a legitimate company name?
- ✅ **`email`**: Does it look professional/legitimate?
- ✅ **`phoneNumber`**: Is it a valid South African number?
- ✅ **`registrationNumber`**: Company registration number (if provided)
- ✅ **`industryType`**: What industry they're in
- ✅ **`companyDescription`**: Brief description of the company
- ✅ **`website`**: Company website (if provided)

**Optional but Helpful:**
- Check if the company website exists and matches the information
- Verify the registration number with CIPC if necessary
- Look for any red flags or suspicious information

### Step 4: Verify or Reject the Employer

#### To VERIFY an employer:

1. Click on the employer's document ID to open it
2. Look for the `verificationStatus` field
3. Click on the field value (should currently show `"pending"`)
4. Change it to: **`"verified"`**
5. Click **Update** or **Save**

**Result:** 
- The employer will immediately see a green "Verified" badge on their profile
- They'll get full access to all employer features
- **Their job postings will automatically show a "Verified" badge** (visible to all job seekers)
- **Their jobs will appear FIRST in search results** (priority sorting enabled)
- Increased trust and visibility for their company

#### To REJECT an employer:

1. Click on the employer's document ID to open it
2. Look for the `verificationStatus` field
3. Click on the field value (should currently show `"pending"`)
4. Change it to: **`"rejected"`**
5. Click **Update** or **Save**

**Result:**
- The employer will see a "Verification Rejected" message
- They'll be prompted to contact support
- Limited features will be available

---

## Quick Reference: Firebase Console Steps

### Visual Guide:

```
Firebase Console
    ↓
Firestore Database
    ↓
users (collection)
    ↓
[Find employer with userType: "employer"]
    ↓
[Click on document ID]
    ↓
verificationStatus: "pending"
    ↓
[Click on field value]
    ↓
Change to: "verified" or "rejected"
    ↓
[Click Update]
    ✓ Done!
```

---

## Verification Status Values

The `verificationStatus` field can have three values:

| Status | Value | Meaning | Display |
|--------|-------|---------|---------|
| **Pending** | `"pending"` | Employer registered but not yet verified | Yellow/Orange warning badge |
| **Verified** | `"verified"` | Employer verified by admin | Green success badge with checkmark |
| **Rejected** | `"rejected"` | Verification request rejected | Red error badge with X |

---

## Finding Pending Verifications Quickly

### Method 1: Using Firestore Console Filters

1. In the `users` collection, click on **"Filter"** or **"Add filter"**
2. Set filter:
   - Field: `verificationStatus`
   - Operator: `==`
   - Value: `pending`
3. Click **Apply**
4. You'll see only pending employers

### Method 2: Manual Search

1. Scroll through the `users` collection
2. Click on each document to check:
   - `userType`: Look for `"employer"`
   - `verificationStatus`: Look for `"pending"`

---

## What Employers See

### Pending Status (Before Verification):
```
⏳ Verification Pending
Your company profile is under review by our team.

What happens next?
1. Our team reviews your company information
2. Verification usually takes 24-48 hours
3. You'll be notified once your profile is verified

⚠️ Limited features available until verified
```

### Verified Status (After Verification):
```
✓ Company Verified
Your company profile has been verified by the administrator.

Benefits of Verification:
✓ Increased trust from job seekers
✓ Priority in search results (your jobs appear FIRST)
✓ Verified badge on all job postings (with green checkmark icon)
✓ Higher visibility to job seekers

Technical Implementation:
- All job postings automatically display a green "Verified" badge
- Jobs are sorted by verification status (verified employers' jobs appear first)
- Badge is visible on job cards, job detail screens, and search results
```

### Rejected Status:
```
✗ Verification Rejected
Your verification request was rejected. Please contact support.

Need Help?
Please contact our support team at support@tiromangaung.co.za 
for more information about your verification status.
```

---

## Best Practices

### ✅ DO:
- Verify employers within 24-48 hours of registration
- Check company information thoroughly before verifying
- Document reasons for rejection (you can add notes in Firestore)
- Verify legitimate businesses only
- Double-check registration numbers with CIPC when possible

### ❌ DON'T:
- Verify without checking company details
- Leave employers pending for more than 48 hours without reason
- Verify suspicious or fake companies
- Reject without reason (consider adding a rejection reason field)

---

## Troubleshooting

### Q: I changed the status but the employer doesn't see it
**A:** The employer may need to:
1. Refresh the app (swipe down on the Profile tab)
2. Log out and log back in
3. Close and reopen the app

The change should be instant, but cached data might delay the update.

### Q: How do I undo a verification?
**A:** Simply go back to the employer's document in Firestore and change `verificationStatus` back to `"pending"` or `"rejected"`.

### Q: Can I add a rejection reason?
**A:** Yes! You can add a new field called `rejectionReason` to the employer's document:
1. Open the employer's document
2. Click **"Add field"**
3. Field name: `rejectionReason`
4. Type: `string`
5. Value: Your reason (e.g., "Invalid registration number")

### Q: What if an employer doesn't have a `verificationStatus` field?
**A:** This means they registered before the verification system was added. You can:
1. Click **"Add field"**
2. Field name: `verificationStatus`
3. Type: `string`
4. Value: `"pending"` (then review and verify)

---

## Security Notes

🔒 **Important:**
- Only authorized administrators should have access to the Firebase console
- Keep your Firebase credentials secure
- Log all verification actions for audit purposes
- Never share admin credentials

---

## Future Enhancements (Coming Soon)

The following features are planned for future updates:

1. **Admin Dashboard**: A dedicated admin panel in the app for managing verifications
2. **Bulk Verification**: Verify multiple employers at once
3. **Automated Verification**: Integration with CIPC API for automatic registration number verification
4. **Email Notifications**: Automatic emails to employers when verified/rejected
5. **Verification History**: Track who verified which employer and when
6. **Rejection Reasons**: Predefined rejection reasons with custom messages
7. **Re-verification Requests**: Allow rejected employers to submit additional information

---

## Support

If you have questions or need assistance with the verification process:

**Email:** support@tiromangaung.co.za  
**Phone:** [Add your support phone number]

---

## Document Version

- **Version:** 1.0
- **Last Updated:** October 16, 2025
- **Created By:** Development Team

---

## Quick Start Checklist for Admins

- [ ] Access Firebase Console
- [ ] Navigate to Firestore Database → `users` collection
- [ ] Filter by `verificationStatus == "pending"` and `userType == "employer"`
- [ ] Review employer information
- [ ] Verify or reject based on legitimacy
- [ ] Confirm employer sees updated status

---

**Remember:** Employer verification is crucial for maintaining trust in the Tiro Mo Mangaung platform. Take time to verify each employer thoroughly! 🎯

---

## Technical Implementation Details

### How Verification Benefits Work Automatically

Once you change an employer's `verificationStatus` to `"verified"` in Firestore, the following happens automatically in the app:

#### 1. **Priority in Search Results**
   - **Implementation**: Jobs are sorted by employer verification status before any other criteria
   - **Logic**: `isEmployerVerified == true` jobs appear before `isEmployerVerified == false` jobs
   - **Applies to**: 
     - All job listings
     - Search results
     - Filtered results
     - "Jobs Near Me" (verified jobs appear first, then sorted by distance)

#### 2. **Verified Badge Display**
   - **Location**: Appears on all job postings wherever they're displayed
   - **Design**: 
     - Green checkmark icon (✓)
     - "Verified" text label
     - Green background with border
     - Tooltip: "Verified Employer"
   - **Visibility**: 
     - Job cards in listings
     - Job detail screens
     - Employer profile (when viewed by job seekers)
     - Application history

#### 3. **Real-Time Updates**
   - **Immediate Effect**: Changes reflect instantly when user refreshes
   - **No Cache Issues**: App fetches fresh data from Firestore on each load
   - **Automatic**: No manual intervention needed after Firestore update

### Data Flow

```
Admin Changes Firestore
        ↓
users/{employerId}/verificationStatus = "verified"
        ↓
App fetches employer data when loading jobs
        ↓
Job cards enriched with isEmployerVerified field
        ↓
Jobs sorted (verified first)
        ↓
Verified badge displayed on UI
        ↓
Job seekers see verified employers' jobs first with badge
```

### Database Schema

**User Document (Employer)**:
```json
{
  "id": "employer_user_id",
  "email": "company@example.com",
  "userType": "employer",
  "companyName": "Example Company",
  "verificationStatus": "verified",  // ← This field controls everything
  // ... other fields
}
```

**Job Document** (enriched at runtime):
```json
{
  "id": "job_id",
  "employerId": "employer_user_id",
  "title": "Software Engineer",
  "isEmployerVerified": true,  // ← Automatically added by app
  // ... other fields
}
```

### Code Locations (For Developers)

If you need to modify the verification system:

1. **Verification Status Field**:
   - Model: `lib/models/user_model.dart` (line 32)
   - Set on registration: `lib/providers/auth_provider.dart` (line 84)

2. **Employer Data Enrichment**:
   - Provider: `lib/providers/job_provider.dart`
   - Method: `_enrichJobsWithEmployerData()`
   - Called in: `fetchJobs()` method

3. **Priority Sorting**:
   - Provider: `lib/providers/job_provider.dart`
   - Logic: Jobs sorted by `isEmployerVerified` first, then by other criteria
   - Applies to: All job listing queries

4. **Verified Badge UI**:
   - Job Cards: `lib/widgets/job_card.dart`
   - Job Detail: `lib/screens/job_seeker/job_detail_screen.dart`
   - Employer Profile: `lib/screens/employer/employer_home_screen.dart`

### Performance Considerations

- **Batch Loading**: Employer verification status is fetched in batch for all jobs
- **No Extra Queries**: One query per unique employer ID (cached for multiple jobs)
- **Efficient Sorting**: Client-side sorting doesn't impact Firestore costs
- **Real-time**: No delays or background jobs needed

---

**The system is fully automated!** Once you verify an employer in Firestore, everything else happens automatically. 🚀
