# Test Certification System

## Quick Test Steps

### 1. Navigate to Certifications
- Go to Student Dashboard
- Click on "Certifications" in the sidebar
- Or use the "Add Certificate" quick action

### 2. Add a Test Certificate
Click "Add Certificate" and fill in:

**Test Data 1 (High Confidence)**:
- Provider: NPTEL (95%)
- Certificate Name: "Python Programming Fundamentals"
- Certificate ID: "NPTEL22CS101234"
- Verification URL: "https://nptel.ac.in/certificates/NPTEL22CS101234"
- Issue Date: Any recent date

**Expected Result**: Should validate as "VALIDATED" with high confidence

**Test Data 2 (Medium Confidence)**:
- Provider: Udemy (85%)
- Certificate Name: "Complete JavaScript Course"
- Certificate ID: "UC-12345678"
- Verification URL: (leave empty)
- Issue Date: Any recent date

**Expected Result**: Should show as "PENDING" for manual review

**Test Data 3 (Low Confidence)**:
- Provider: Coursera (90%)
- Certificate Name: "Test"
- Certificate ID: "123"
- Verification URL: "http://invalid-url.com"
- Issue Date: Any recent date

**Expected Result**: Should be "REJECTED" due to low confidence

### 3. Check Results
- Certificates should appear in the grid
- Status badges should show correct validation status
- Skills should be extracted (e.g., "Python", "JavaScript")
- No rendering exceptions should occur

### 4. Test Different Views
- Switch between tabs: All, Validated, Pending, Skills Gained
- Check that filtering works correctly
- Verify stats cards show correct numbers

## Expected Behavior

### ✅ Working Features
- Dropdown selection without rendering errors
- Certificate upload and validation
- Fallback validation when Edge Function unavailable
- Basic skill extraction from certificate names
- Status determination based on confidence scores
- Responsive grid layout
- Tab-based filtering

### 🔧 Fallback Validation
When Edge Function is not deployed:
- Uses pattern matching for validation
- Checks URL domains against provider websites
- Extracts skills from certificate names
- Provides confidence scores based on available data
- Gracefully handles missing information

### 📊 Confidence Calculation
- Certificate name provided: +30 points
- HTTPS URL: +20 points
- Domain matches provider: +30 points
- Valid certificate ID format: +20 points
- Adjusted by provider trust score (85-95%)

## Troubleshooting

### If certificates don't appear:
1. Check browser console for errors
2. Verify database migration was run
3. Check Supabase authentication

### If validation fails:
1. System will use fallback validation
2. Check certificate details for completeness
3. Ensure provider is selected correctly

### If skills aren't extracted:
1. Use descriptive certificate names
2. Include technology keywords (Python, JavaScript, etc.)
3. Skills database may need to be populated

## Success Criteria ✅
- [ ] Can open certification screen without errors
- [ ] Can select provider from dropdown
- [ ] Can fill and submit certificate form
- [ ] Certificate appears in grid with status
- [ ] Skills are extracted and displayed
- [ ] No Flutter rendering exceptions
- [ ] Fallback validation works when Edge Function unavailable