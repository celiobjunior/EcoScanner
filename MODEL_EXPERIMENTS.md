# MODEL_EXPERIMENTS.md - End-to-End Training Workflow and Experiment Log

Last updated: 2026-02-15

## 1) Objective, Decision Rule, and Current Status

Primary objective in this cycle:
- Improve real-time scanner quality without breaking the in-app flow.
- Optimize **main test accuracy** on a fixed reference split.
- Keep behavior stable under cluttered real scenes.

Decision rule used:
1. Compare models on the same fixed main test split (`505` images).
2. Use extra tests (`Other Testing`) as robustness signal, not as primary ranking metric.
3. Prefer stable cross-split behavior over a single best number.

Current status:
- Current integrated model artifact in app:
  - `/Users/celio/Documents/untitled folder/EcoScannerObjDetec.mlmodel`
  - compiled and copied to:
  - `/Users/celio/Documents/untitled folder/EcoScanner.swiftpm/Resources/MLModel/EcoScanner.mlmodelc`
- Current detector classes in production pipeline:
  - `BIODEGRADABLE`, `CARDBOARD`, `GLASS`, `METAL`, `PAPER`, `PLASTIC`

## 2) Datasets Used and Why

### 2.1 Legacy classification track (before object detection)

This project started with image classification in Create ML (not box detection), using user-curated data:
- 3 Kaggle garbage datasets
- ~`29,364` items
- `13` classes
- settings used in that phase: `Image Feature Print v2`, `25 iterations`, automatic validation split

Why this track was deprioritized:
- Better class prediction did not guarantee stable object localization behavior in the scanner.
- Product requirement shifted to object-level behavior (box + better scan focus behavior).

### 2.2 Object detection base dataset

Base root:
- `/Users/celio/Documents/untitled folder/trash-detection`

This root contains both:
- YOLO-style files (`<split>/labels/*.txt`) and
- Create ML-style annotations (`<split>/images/annotation.json`)

Data contract in `data.yaml`:
- `nc: 6`
- names:
  - `BIODEGRADABLE`
  - `CARDBOARD`
  - `GLASS`
  - `METAL`
  - `PAPER`
  - `PLASTIC`

### 2.3 External augmentation datasets

Litterati:
- `/Users/celio/Documents/untitled folder/Litterati Collection and Labeling`
- Format: Supervisely (`ds0/ann/*.json`, `ds0/img/*`)

TACO:
- `/Users/celio/Documents/untitled folder/TACO`
- Format: COCO (`data/annotations.json` + `data/*`)

## 3) Exact Format Expected by Create ML (Object Detection)

Create ML Object Detection expects each split as:
- `<split>/images/*`
- `<split>/images/annotation.json`

`annotation.json` record shape:

```json
[
  {
    "image": "example.jpg",
    "annotations": [
      {
        "label": "PLASTIC",
        "coordinates": {
          "x": 123.4,
          "y": 210.8,
          "width": 64.0,
          "height": 92.0
        }
      }
    ]
  }
]
```

Important:
- Coordinates are pixel-space center format (`x`, `y`, `width`, `height`), not normalized YOLO format.
- This is why YOLO text labels cannot be used directly in Create ML without conversion.

## 4) Python Workflow Actually Used

All scripts used in this cycle live in:
- `/Users/celio/Documents/untitled folder/trash-detection/tools`

### 4.0 Initial YOLO -> Create ML conversion (base preparation)

Raw source had YOLO labels per image:
- `<split>/labels/<image>.txt`
- each line: `<class_id> <x_center_norm> <y_center_norm> <w_norm> <h_norm>`

Create ML requires:
- `<split>/images/annotation.json`
- pixel-space center boxes (`x`, `y`, `width`, `height`)

Conversion logic used:
1. Read image size `(W, H)`.
2. Convert normalized YOLO box to pixels:
   - `x = x_center_norm * W`
   - `y = y_center_norm * H`
   - `width = w_norm * W`
   - `height = h_norm * H`
3. Map `class_id` using `data.yaml` order:
   - `0 BIODEGRADABLE, 1 CARDBOARD, 2 GLASS, 3 METAL, 4 PAPER, 5 PLASTIC`
4. Emit Create ML annotation JSON entries.

Minimal Python shape (equivalent logic):

```python
label = names[int(class_id)]
annotation = {
    "label": label,
    "coordinates": {
        "x": x_center_norm * image_w,
        "y": y_center_norm * image_h,
        "width": w_norm * image_w,
        "height": h_norm * image_h
    }
}
```

Important:
- After this initial conversion, the dataset root kept both:
  - YOLO files in `labels/`
  - Create ML files in `images/annotation.json`
- All downstream scripts in this project operate on Create ML JSON.

### 4.1 Base cleanup + balancing script

Script:
- `/Users/celio/Documents/untitled folder/trash-detection/tools/prepare_create_ml_dataset.py`

What it does:
1. Reads Create ML annotations per split (`train`, `valid`, `test`).
2. Drops low-quality boxes by geometry:
   - `min_area_ratio = 0.003`
   - `min_side_ratio = 0.03`
   - `max_aspect_ratio = 10.0`
3. Balances **train only** with per-class caps.
4. Writes new dataset root preserving Create ML format.
5. Uses `hardlink` by default to avoid duplicating image bytes.

Default command pattern:

```bash
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/prepare_create_ml_dataset.py" \
  --src-root "/Users/celio/Documents/untitled folder/trash-detection" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v2" \
  --seed 42 \
  --copy-mode hardlink
```

Notes:
- `--train-target-instances` can force one global cap.
- `--train-class-targets-json` can force class-specific caps.

### 4.2 Litterati integration script

Script:
- `/Users/celio/Documents/untitled folder/trash-detection/tools/integrate_litterati_dataset.py`

What it does:
1. Converts Supervisely rectangles (`points.exterior`) to Create ML boxes.
2. Applies conservative mapping:
   - `plastic`, `polystyrene` -> `PLASTIC`
   - `paper` -> `PAPER`
   - `glass` -> `GLASS`
   - `aluminum`, `metal` -> `METAL`
   - `tetrapak` -> `CARDBOARD`
3. Fallback only when material is missing/invalid:
   - `box`, `drinkcarton` -> `CARDBOARD`
   - `newspaper` -> `PAPER`
4. Merges mapped Litterati into **train only**.
5. Keeps base `valid/test` unchanged.
6. Creates `extra_test` via stratified split by primary label (`extra_test_ratio=0.10`, `seed=42`).
7. Writes `merge_summary.json` with conversion + integrity stats.

Command used pattern:

```bash
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/integrate_litterati_dataset.py" \
  --base-root "/Users/celio/Documents/untitled folder/trash-detection-v3" \
  --litterati-root "/Users/celio/Documents/untitled folder/Litterati Collection and Labeling" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v3-litterati-v2" \
  --extra-test-ratio 0.10 \
  --seed 42 \
  --copy-mode hardlink
```

Summary files:
- `/Users/celio/Documents/untitled folder/trash-detection-v3-litterati-v2/merge_summary.json`
- `/Users/celio/Documents/untitled folder/trash-detection-v3b-litterati-v1/merge_summary.json`

### 4.3 TACO integration script

Script:
- `/Users/celio/Documents/untitled folder/trash-detection/tools/integrate_taco_dataset.py`

What it does:
1. Converts COCO boxes (`[x_min, y_min, w, h]`) to Create ML center format.
2. Applies conservative category map into the same 6 classes.
3. Merges mapped TACO into **train only**.
4. Keeps base `valid/test` unchanged.
5. Creates `extra_test_taco` (`extra_test_ratio=0.10`, `seed=42`).
6. Writes `merge_summary_taco.json` with conversion + integrity stats.

Command used pattern:

```bash
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/integrate_taco_dataset.py" \
  --base-root "/Users/celio/Documents/untitled folder/trash-detection-v3b" \
  --taco-root "/Users/celio/Documents/untitled folder/TACO" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v3b-taco-v1" \
  --extra-test-ratio 0.10 \
  --seed 42 \
  --copy-mode hardlink
```

Summary file:
- `/Users/celio/Documents/untitled folder/trash-detection-v3b-taco-v1/merge_summary_taco.json`

## 5) Split Policy and Why It Matters

Core policy used across experiments:
1. Keep base `valid` and `test` fixed for fair A/B.
2. Modify only `train` when adding new data.
3. Put external robustness checks in separate extra splits:
   - `extra_test` (Litterati)
   - `extra_test_taco` (TACO)

Why:
- Prevent misleading improvements caused by changing evaluation distribution.
- Make `main test` numbers historically comparable run-to-run.

### 5.1 Base split sizes (raw Create ML annotations)

From `/Users/celio/Documents/untitled folder/trash-detection`:
- train: `3533 images / 23512 objects`
- valid: `1008 images / 7284 objects`
- test: `505 images / 3286 objects`

### 5.2 Derived split sizes used in detector experiments

- `trash-detection-v3`:
  - train: `3461 / 15808`
  - valid: `1008 / 5682`
  - test: `505 / 2814`

- `trash-detection-v3b`:
  - train: `3470 / 16808`
  - valid: `1008 / 5682`
  - test: `505 / 2814`

- `trash-detection-v3-litterati-v2`:
  - train: `6145 / 18497`
  - valid: `1008 / 5682`
  - test: `505 / 2814`
  - extra_test: `298 / 298`

- `trash-detection-v3b-litterati-v1`:
  - train: `6154 / 19497`
  - valid: `1008 / 5682`
  - test: `505 / 2814`
  - extra_test: `298 / 298`

- `trash-detection-v3b-taco-v1`:
  - train: `4770 / 19990`
  - valid: `1008 / 5682`
  - test: `505 / 2814`
  - extra_test_taco: `144 / 349`

## 6) Litterati/TACO Conversion Outcomes (from summaries)

### Litterati conversion

From `merge_summary.json`:
- `ann_files_total`: `3201`
- `records_kept`: `2982`
- `objects_kept`: `2987`
- `objects_skipped_unmapped`: `219`
- `objects_skipped_invalid_box`: `0`
- `fallback_used`: `6`
- class counts kept:
  - `PLASTIC: 1374`
  - `PAPER: 745`
  - `METAL: 428`
  - `GLASS: 259`
  - `CARDBOARD: 181`
- split:
  - train_records: `2684`
  - extra_test_records: `298`

### TACO conversion

From `merge_summary_taco.json`:
- `images_total`: `1500`
- `annotations_total`: `4784`
- `records_kept`: `1444`
- `objects_kept`: `3531`
- `objects_skipped_unmapped`: `1253`
- `objects_skipped_invalid_box`: `0`
- split:
  - train_records: `1300`
  - extra_test_records: `144`

Integrity checks in both workflows:
- `missing_images = 0`
- `invalid_boxes = 0`

## 7) Create ML Training Workflow (UI)

### 7.1 Project setup in Create ML (Object Detection)

For consistent A/B:
1. Training Data: `.../train/images`
2. Validation Data: `.../valid/images`
3. Testing Data: `.../test/images`
4. Optional extra tests via `+ New Test`:
   - `.../extra_test/images`
   - `.../extra_test_taco/images`

Important:
- Compare models by `Testing` on **images (From Initial Setup)** (the fixed `505` split).
- `Other Testing` is robustness check only.

### 7.2 Algorithms and settings used

Full Network (early baseline):
- Iterations: `3000`
- Batch: `Auto`
- Grid: `13x13`

Transfer Learning (main line):
- Batch: `Auto`
- Iterations tested: `8000`, `11000`, `12000`
- Most competitive runs: around `11000-12000`

Tip discovered during evaluation:
- When pressing test in Create ML and a modal asks:
  - "How many additional training iterations?"
- Use `Cancel` when the goal is only evaluating current weights on extra test.

## 8) Chronological Experiment Log

All metrics below were reported during this project cycle.

| Experiment | Train/Val/Test | Notes |
|---|---:|---|
| Full Network (3000, 13x13) | `38/30/29` | Early detector baseline, weak. |
| Transfer Learning (8000) | `80/44/53` | Large jump over Full Network. |
| v3 normal (`MyObjectDetector 3`) | `85/44/51` | Stable base reference. |
| v3+litterati intermediate (`MyObjectDetector 4`) | `78/46/54` (main test retest) | Early `62%` came from 5-class/298-item test and was not comparable with main test. |
| v3-litterati-v2 (`MyObjectDetector 5`) | `80/46/53` | Chosen as safer baseline in this phase. |
| v3-litterati-v2 extra_test | `80/46/61` | Strong on Litterati robustness split. |
| v3b normal (`MyObjectDetector 6`) | `86/44/51` | Better train only; same main-test plateau. |
| v3b-taco-v1 (`MyObjectDetector 7`) | `75/46/54` | Best observed on fixed main test (`54`). |
| v3b-taco-v1 extra_test_taco | `75/46/12` | Severe domain-shift collapse on TACO extra test. |

## 9) Why the Split Decisions Stayed Strict

Without fixed `valid/test`, results would be inflated by dataset changes instead of model improvements.

Decisions enforced:
1. `valid/test` fixed to original base split in all merge experiments.
2. External data (Litterati/TACO) entered as:
   - train enrichment
   - separate robustness tests (`extra_test*`)
3. Any run evaluated only on non-fixed split was marked as non-comparable.

## 10) Current Integrated Artifact Metadata

Source file:
- `/Users/celio/Documents/untitled folder/EcoScannerObjDetec.mlmodel`

Checksums and size:
- source SHA-256:
  - `ee295fd138815de11ed440011ecee16f26dba295d75c11417a0b632ae33ebc9d`
- source size:
  - `7,246,552 bytes` (~6.9 MB)
- compiled folder checksum (manifest):
  - `9b3e2b8ac82b4c28154fda06fe6ba82edf1efd9f1ba7a1bcd9ba59ca5768fe8c`
- compiled payload size:
  - `7,355,613 bytes` (~7.0 MB)

Class list from compiled metadata:
- `BIODEGRADABLE`
- `CARDBOARD`
- `GLASS`
- `METAL`
- `PAPER`
- `PLASTIC`

## 11) Reproducibility Cheat Sheet (Commands)

### 11.1 Build cleaned baseline variant

```bash
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/prepare_create_ml_dataset.py" \
  --src-root "/Users/celio/Documents/untitled folder/trash-detection" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v2" \
  --seed 42 \
  --copy-mode hardlink
```

### 11.1.1 Build v3 / v3b balancing profiles (BIO cap tuning)

Observed train class counts show:
- `v3` profile capped `BIODEGRADABLE` at `6000`
- `v3b` profile capped `BIODEGRADABLE` at `7000`

The exact historical command lines for these two runs were not persisted in a log file, but the following command pattern reproduces the same cap strategy:

```bash
# v3-like profile
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/prepare_create_ml_dataset.py" \
  --src-root "/Users/celio/Documents/untitled folder/trash-detection" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v3" \
  --train-target-instances 2382 \
  --train-class-targets-json '{"BIODEGRADABLE":6000}' \
  --seed 42 \
  --copy-mode hardlink

# v3b-like profile
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/prepare_create_ml_dataset.py" \
  --src-root "/Users/celio/Documents/untitled folder/trash-detection" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v3b" \
  --train-target-instances 2382 \
  --train-class-targets-json '{"BIODEGRADABLE":7000}' \
  --seed 42 \
  --copy-mode hardlink
```

### 11.2 Build Litterati merged variant

```bash
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/integrate_litterati_dataset.py" \
  --base-root "/Users/celio/Documents/untitled folder/trash-detection-v3" \
  --litterati-root "/Users/celio/Documents/untitled folder/Litterati Collection and Labeling" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v3-litterati-v2" \
  --extra-test-ratio 0.10 \
  --seed 42 \
  --copy-mode hardlink
```

### 11.3 Build TACO merged variant

```bash
python3 "/Users/celio/Documents/untitled folder/trash-detection/tools/integrate_taco_dataset.py" \
  --base-root "/Users/celio/Documents/untitled folder/trash-detection-v3b" \
  --taco-root "/Users/celio/Documents/untitled folder/TACO" \
  --dst-root "/Users/celio/Documents/untitled folder/trash-detection-v3b-taco-v1" \
  --extra-test-ratio 0.10 \
  --seed 42 \
  --copy-mode hardlink
```

### 11.4 Compile and integrate model into app

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/coremlc compile \
  "/Users/celio/Documents/untitled folder/EcoScannerObjDetec.mlmodel" \
  "/Users/celio/Documents/untitled folder/EcoScanner.swiftpm/Resources/MLModel"
```

## 12) Open Risks and Next Actions

Known risks:
1. Main-test gains can hide brittleness in out-of-distribution scenes.
2. TACO integration currently has mapping loss (`1253` unmapped objects), which may explain poor extra-test behavior.
3. Class imbalance remains high (`BIODEGRADABLE` dominates most splits).

Next practical actions:
1. Keep fixed main split protocol unchanged.
2. Improve mapping coverage for TACO before next training.
3. Re-run Transfer Learning `12000` with same split policy and compare:
   - main test (`505`)
   - extra tests (`extra_test`, `extra_test_taco`)
4. Promote only if main-test gain does not collapse on robustness splits.
