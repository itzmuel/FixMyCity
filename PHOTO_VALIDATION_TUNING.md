# Photo Validation Threshold Tuning Guide

## Overview

The photo validation system now uses several tunable thresholds to control acceptance/rejection behavior. This guide helps you calibrate them based on your real user submissions.

## Current Thresholds

### 1. Brightness (Luminance)
**Location**: `lib/services/upload_validation.dart` — `_checkImageQuality()`

```dart
if (brightness < 35) {
  return PhotoValidationResult.fail(..., code: PhotoValidationCode.tooDark);
}
if (brightness > 225) {
  return PhotoValidationResult.fail(..., code: PhotoValidationCode.tooBright);
}
```

- **Too Dark**: brightness < 35
- **Too Bright**: brightness > 225

**Tuning Guidance**:
- If you see many night/outdoor street photo rejections, lower the "too dark" threshold (e.g., 25).
- If daytime photos with bright skies are rejected, raise "too bright" to 240.

### 2. Blur Detection (Laplacian Variance)
**Location**: `lib/services/upload_validation.dart` — `_checkImageQuality()`

```dart
final blurScore = _varianceOfLaplacian(sample);
if (blurScore < 90) {
  return PhotoValidationResult.fail(..., code: PhotoValidationCode.tooBlurry);
}
```

- **Threshold**: 90

**Tuning Guidance**:
- If sharp handheld photos are rejected, lower to 70–80.
- If blurry photos slip through, raise to 110–120.

### 3. Civic Relevance Score
**Location**: `lib/services/upload_validation.dart` — `_checkLocalRelevance()`

```dart
if (score < 0.30) {
  return PhotoValidationResult.fail(
    'We could not detect a clear civic issue...',
    code: PhotoValidationCode.notCivicRelevant,
    score: score,
  );
}
```

- **Threshold**: 0.30 (score out of 1.0)

**Components** (in `_estimateRelevanceScore()`):
- Base: 0.5
- Edge density (0.025–0.45): +0.16
- Edge density < 0.015: –0.20
- Luminance variance ≥ 320: +0.14
- Luminance variance < 320: –0.12
- Mean saturation ≥ 0.08: +0.07
- Description ≥ 16 chars: +0.06
- Category keywords match: +0.10
- Category = "Other": –0.04

**Tuning Guidance**:
- If generic/off-topic photos are slipping through, **raise to 0.40–0.50**.
- If valid civic issues are rejected, **lower to 0.20–0.25**.
- Tweak individual component weights in `_estimateRelevanceScore()` if a specific signal (e.g., edge detection) is too strong/weak.

### 4. Server Moderation Threshold
**Location**: `lib/services/photo_moderation_service.dart`

```dart
'threshold': 0.65,
```

- **Threshold**: 0.65 (sent to Edge Function)

**Tuning Guidance**:
- Server threshold is separate and independent of local checks.
- Raise to 0.75–0.80 to be more permissive (allow edge-case reports).
- Lower to 0.50–0.60 to be stricter (block borderline civic content).

---

## Tuning Workflow

### Step 1: Collect Sample Photos
Gather rejected and accepted photos from your app or test data. Organize by category:

```
samples/
├── potholes/
│   ├── good_pothole_1.jpg
│   ├── good_pothole_2.jpg
│   └── bad_selfie_pothole.jpg
├── graffiti/
│   ├── good_graffiti_1.jpg
│   └── bad_blurry_graffiti.jpg
└── other/
    └── unrelated_photo.jpg
```

### Step 2: Run Tuning Analysis
Create a test script or widget that uses `analyzePhotoForTuning()`:

#### Option A: Command-line test (dart script)
```dart
import 'lib/services/photo_validation_tuning.dart';
import 'lib/models/issue_category.dart';

void main() async {
  final testFile = 'samples/potholes/good_pothole_1.jpg';
  final report = await analyzePhotoForTuning(
    testFile,
    category: IssueCategory.pothole,
    description: 'Large pothole on Main St',
  );
  report.printAnalysis();
}
```

#### Option B: Debug widget (in-app testing)
Add a hidden debug button in the photo review screen that shows the tuning report instead of just accept/reject.

### Step 3: Analyze Results
For each photo, review the tuning report:

```
=== Photo Validation Tuning Report ===
File: samples/potholes/good_pothole_1.jpg
Category: Pothole
Valid: true
Error: none

--- Image Profile ---
Edge Density: 0.1234
Luminance Variance: 450.50
Mean Saturation: 0.1200

--- Component Scores ---
brightness: 120.5
blurScore: 105.3
edgeDensity: 0.1234
luminanceVariance: 450.50
meanSaturation: 0.1200
relevanceScore: 0.7200

Recommendation: ACCEPT
```

**What each metric means**:
- **Edge Density**: Higher = more structure/detail. Potholes typically 0.05–0.25.
- **Luminance Variance**: Higher = more lighting variation. Well-lit outdoor scenes: 300+.
- **Brightness**: 50–150 is typical; <35 is very dark, >225 is very bright.
- **Blur Score**: Higher = sharper. >90 is generally sharp, <70 is blurry.
- **Relevance Score**: 0.6–1.0 is strong civic signal; <0.35 is weak.

### Step 4: Identify False Positives & Negatives

**False Positive** (rejected but should accept):
- Too strict thresholds.
- Adjust downward and re-test.

**False Negative** (accepted but should reject):
- Too permissive thresholds.
- Adjust upward and re-test.

### Step 5: Update Thresholds in Code

Once you identify which thresholds need adjustment:

1. **Brightness too dark**: Edit `_checkImageQuality()`, change `brightness < 35` to e.g. `brightness < 25`.
2. **Blur too strict**: Change `blurScore < 90` to `blurScore < 75`.
3. **Relevance too strict**: Change `score < 0.30` to `score < 0.20`.

### Step 6: Re-test & Iterate

Run the tuning analysis on your full sample set again. Track false positives and false negatives. Aim for:
- False positive rate < 5% (rejecting valid reports).
- False negative rate < 10% (accepting bad reports).

---

## Batch Analysis for Calibration

Create a simple batch-test tool to analyze all samples at once:

```dart
import 'dart:convert';
import 'package:path/path.dart' as p;

Future<void> batchAnalyzeSamples(String sampleDir) async {
  final dir = Directory(sampleDir);
  if (!await dir.exists()) {
    print('Sample directory not found: $sampleDir');
    return;
  }

  final results = <Map<String, dynamic>>[];

  for (final entry in dir.listSync(recursive: true)) {
    if (entry is File && _isImageFile(entry.path)) {
      final report = await analyzePhotoForTuning(entry.path);
      results.add(report.toJson());
      report.printAnalysis();
    }
  }

  // Save results to JSON for spreadsheet analysis
  final json = jsonEncode(results);
  File('validation_tuning_results.json').writeAsStringSync(json);
  print('Results saved to validation_tuning_results.json');
}

bool _isImageFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
}
```

Then import into a spreadsheet and use pivot tables to find thresholds that minimize false positives/negatives.

---

## Recommendations for FixMyCity

Based on typical civic issue photos:

| Threshold | Recommended Value | Rationale |
|-----------|-------------------|-----------|
| Brightness (too dark) | **25–30** | Outdoor street issues may be twilight/dusk |
| Brightness (too bright) | **230–240** | Avoid rejecting daytime photos with reflections |
| Blur Score | **80–90** | Handheld outdoor photos often slightly soft |
| Relevance Score | **0.25–0.35** | Civic issues can have varied visual features |
| Server Threshold | **0.60–0.70** | Moderate permissiveness for edge cases |

---

## Monitoring & Analytics

The app now logs moderation decisions to `report_moderation_events`:

```sql
-- Count rejections by reason code
SELECT reason_code, COUNT(*) as count
FROM report_moderation_events
WHERE decision = 'deny'
GROUP BY reason_code
ORDER BY count DESC;

-- Find patterns in civic vs. non-civic rejections
SELECT category, COUNT(*) as rejects
FROM report_moderation_events
WHERE reason_code = 'notCivicRelevant'
GROUP BY category;
```

Use these queries to identify systemic over/under-rejection patterns and feed results back into threshold tuning.

---

## Troubleshooting

**Too many face rejections?**
- ML Kit face detector may be over-sensitive. Check Android/iOS ML Kit version and model updates.
- Lower detection threshold in `_detectFace()` if necessary (add `minConfidenceThreshold` param).

**Blurry photos still passing?**
- Laplacian variance may be weak on certain image types (e.g., smooth surfaces).
- Combine with secondary blur metric (e.g., frequency analysis) if needed.

**Civic relevance score always high?**
- Category keywords may be too generic. Tighten keyword lists in `_categoryKeywords()`.
- Reduce edge density weight if sparse/minimal-detail photos pass.

---

## Next Steps

1. Gather real user rejection data from `report_moderation_events`.
2. Run batch analysis on 50–100 representative photos.
3. Adjust thresholds and re-test.
4. Deploy updated values to production.
5. Monitor analytics weekly and iterate.
