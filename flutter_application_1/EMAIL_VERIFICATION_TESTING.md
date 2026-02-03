# Email Verification Testing Guide

## 🧪 Quick Test Procedure

### Test 1: Job Seeker Registration with Verification

1. **Open the app**
   - Should land on login screen (or onboarding if first time)

2. **Tap "Create Account"**
   - Navigate to registration screen

3. **Fill in job seeker details**
   - Email: Use a real email you can access
   - Password: Any valid password
   - Full Name: Test User
   - Phone: Valid phone number
   - User Type: Job Seeker

4. **Tap "Create Account"**
   - ✅ Account created successfully
   - ✅ Verification email sent automatically

5. **Expected Behavior**
   - Should redirect to **Email Verification Screen**
   - Screen should show:
     - "Verify Your Email" title
     - Your email address
     - "Resend Verification Email" button
     - "I've Verified My Email" button
     - Auto-checking message every 3 seconds

6. **Check your email inbox**
   - Look for Firebase verification email
   - Subject: Something like "Verify your email"
   - From: noreply@<your-project>.firebaseapp.com

7. **Click the verification link in email**
   - Opens browser
   - Shows Firebase success page

8. **Return to app**
   - Within 3 seconds, should auto-detect verification
   - Success dialog appears: "Email Verified!" ✅
   - Tap "Continue"

9. **Should redirect to Job Seeker Home**
   - `/home` route
   - No verification banner should appear
   - Full app access granted

---

### Test 2: Employer Registration with Verification

Same as Test 1, but:
- Select "Employer" as user type
- Fill in company name, registration number, industry
- Should redirect to `/employer-home` after verification

---

### Test 3: Resend Verification Email

1. **Register new account** (don't verify)
2. **On verification screen, tap "Resend Verification Email"**
   - ✅ Shows loading spinner
   - ✅ Button disabled for 60 seconds
   - ✅ Countdown shows: "Resend in 59s, 58s, 57s..."
   - ✅ Success SnackBar: "Verification email sent!"
3. **Check email again**
   - New verification email should arrive
4. **Try clicking Resend again immediately**
   - ✅ Button should be disabled
   - ✅ Countdown should prevent spam

---

### Test 4: Manual Verification Check

1. **On verification screen, click email link**
2. **DON'T wait for auto-check**
3. **Tap "I've Verified My Email" button**
   - ✅ Should check immediately
   - ✅ Success dialog appears
   - ✅ Navigate to home

---

### Test 5: Router Protection

1. **Register account but DON'T verify email**
2. **Close app completely**
3. **Reopen app**
   - ✅ Should redirect to `/verify-email`
   - ✅ Cannot access home screens
4. **Try manually navigating** (if you can trigger routes)
   - Attempts to access `/home` should redirect to `/verify-email`
   - Attempts to access `/employer-home` should redirect to `/verify-email`

---

### Test 6: Sign Out from Verification Screen

1. **On verification screen, scroll to bottom**
2. **Tap "Sign Out"**
   - ✅ Should log out
   - ✅ Redirect to `/login`
3. **Log back in**
   - ✅ Should redirect to `/verify-email` again

---

### Test 7: Verification Banner (Edge Case)

**Note:** The banner should NOT appear if router protection is working correctly, but test this scenario:

1. **If somehow a user accesses home without verification**
   - Orange banner should appear at top
   - Shows: "Email Not Verified"
   - "Resend" button available
   - Refresh icon to check status

---

## ✅ Success Criteria

### Registration Flow
- [ ] Verification email sent automatically on signup
- [ ] Email arrives within 30-60 seconds
- [ ] Email contains working verification link
- [ ] Link opens in browser successfully

### Verification Screen
- [ ] Displays correct user email
- [ ] Auto-checks every 3 seconds
- [ ] Manual check button works
- [ ] Resend button sends new email
- [ ] 60-second cooldown works
- [ ] Success dialog appears after verification
- [ ] Navigation to home works

### Router Protection
- [ ] Unverified users redirected to `/verify-email`
- [ ] Verified users can access all routes
- [ ] Protection persists across app restarts

### Edge Cases
- [ ] Sign out works from verification screen
- [ ] Multiple resend attempts don't cause errors
- [ ] Offline behavior (shows error message)
- [ ] Already verified users don't see verification screen

---

## 🐛 Known Issues to Watch For

### Firebase Email Delays
- Emails can take 30-60 seconds in development
- Check spam folder if not received in 2 minutes

### Auto-Check Not Detecting
- Firebase may cache verification status
- Manual check button forces refresh
- Worst case: close and reopen app

### Resend Cooldown
- Users may complain about waiting 60 seconds
- This is intentional to prevent spam
- Explain it's for security

---

## 📊 Test Results Template

```
Test Date: ___________
Tester: ___________

Job Seeker Registration:        [ ] Pass  [ ] Fail
Employer Registration:           [ ] Pass  [ ] Fail
Resend Email:                    [ ] Pass  [ ] Fail
Manual Check:                    [ ] Pass  [ ] Fail
Router Protection:               [ ] Pass  [ ] Fail
Sign Out:                        [ ] Pass  [ ] Fail
Auto-Detection:                  [ ] Pass  [ ] Fail

Notes:
_________________________________
_________________________________
_________________________________

Overall: [ ] All Tests Passed  [ ] Issues Found
```

---

## 🚀 Ready to Test!

The email verification feature is complete. Follow the tests above to ensure everything works as expected. 

**Remember:** Use a real email address you can access to receive the verification link!
