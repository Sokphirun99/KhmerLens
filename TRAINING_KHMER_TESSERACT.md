# Training Custom Khmer Tesseract Data

## 🎯 Overview

You can train your own `khm.traineddata` file to improve OCR accuracy for:
- Specific fonts (e.g., document fonts, handwriting styles)
- Better accuracy for your document types
- Custom vocabulary (legal terms, names, etc.)

---

## 📋 Prerequisites

### Required Tools

1. **Tesseract OCR** (v4.0+)
   ```bash
   # macOS
   brew install tesseract
   
   # Ubuntu/Debian
   sudo apt-get install tesseract-ocr tesseract-ocr-dev
   
   # Verify installation
   tesseract --version
   ```

2. **Training Tools**
   ```bash
   # Clone tesstrain repository
   git clone https://github.com/tesseract-ocr/tesstrain.git
   cd tesstrain
   
   # Install dependencies (Python 3, required packages)
   pip install -r requirements.txt
   ```

3. **Image Processing Tools**
   ```bash
   # ImageMagick (for image processing)
   brew install imagemagick  # macOS
   sudo apt-get install imagemagick  # Linux
   ```

---

## 🚀 Training Process

### Step 1: Prepare Training Data

You need:
- **Images**: High-quality images with Khmer text (PNG, TIFF format)
- **Ground Truth**: Text files with exact transcriptions (UTF-8)

**Directory Structure:**
```
training_data/
├── images/
│   ├── doc_001.png
│   ├── doc_002.png
│   └── ...
└── ground_truth/
    ├── doc_001.gt.txt
    ├── doc_002.gt.txt
    └── ...
```

**Example `doc_001.gt.txt`:**
```
សូមអនុញ្ញាតឱ្យខ្ញុំបញ្ជាក់ថា...
```

### Step 2: Generate Box Files (Character Bounding Boxes)

```bash
# Navigate to tesstrain directory
cd tesstrain

# Generate .box files from images
tesseract training_data/images/doc_001.png training_data/ground_truth/doc_001 \
  -l khm lstm.train

# This creates: doc_001.box (character bounding boxes)
```

**Or use automated tool:**
```bash
# Use tesstrain's makebox tool
make training MODEL_NAME=khm TESSDATA=path/to/tessdata
```

### Step 3: Create LSTM Training Files

```bash
# Convert .box files to .lstmf format
tesseract training_data/images/doc_001.png training_data/lstmf/doc_001 \
  -l khm lstm.train

# This creates: doc_001.lstmf
```

### Step 4: Train the Model

#### Option A: Fine-tune Existing Model (Recommended)

```bash
# Start from existing khm.traineddata
lstmtraining \
  --model_output output/khm \
  --continue_from path/to/khm.traineddata \
  --train_listfile training_data/lstmf/train.list \
  --eval_listfile training_data/lstmf/eval.list \
  --traineddata path/to/khm.traineddata \
  --max_iterations 10000
```

#### Option B: Train from Scratch

```bash
# Create starter traineddata
combine_lang_model \
  --input_unicharset langdata/khm/khm.unicharset \
  --script_dir langdata \
  --output_dir output \
  --lang khm

# Train LSTM
lstmtraining \
  --model_output output/khm \
  --train_listfile training_data/lstmf/train.list \
  --eval_listfile training_data/lstmf/eval.list \
  --traineddata output/khm/khm.traineddata \
  --max_iterations 10000
```

### Step 5: Combine into Final .traineddata

```bash
# Stop training (Ctrl+C) when loss is low enough
# Then combine components:

lstmtraining \
  --stop_training \
  --continue_from output/khm_checkpoint \
  --traineddata output/khm/khm.traineddata \
  --model_output output/khm.traineddata

# Final file: output/khm.traineddata
```

### Step 6: Test Your Model

```bash
# Test with a sample image
tesseract test_image.png output -l khm --tessdata-dir output/

# Compare accuracy with original model
```

---

## 📊 Training Data Requirements

### Minimum Requirements
- **100+ images** for basic fine-tuning
- **1000+ images** for training from scratch
- **High quality**: 300+ DPI, clear text, good contrast
- **Diverse**: Different fonts, sizes, layouts

### Best Practices
1. **Use real documents** (not just synthetic fonts)
2. **Include various font sizes** (8pt to 24pt)
3. **Mix document types** (IDs, certificates, receipts)
4. **Include common errors** you want to fix
5. **Split data**: 80% training, 20% evaluation

---

## 🛠️ Quick Start Script

Create `train_khmer.sh`:

```bash
#!/bin/bash

# Configuration
MODEL_NAME="khm"
TRAINING_DATA_DIR="training_data"
OUTPUT_DIR="output"
ITERATIONS=10000

# Step 1: Prepare data
echo "Preparing training data..."
mkdir -p ${OUTPUT_DIR}

# Step 2: Generate .lstmf files
echo "Generating LSTM training files..."
find ${TRAINING_DATA_DIR}/images -name "*.png" | while read img; do
  base=$(basename "$img" .png)
  tesseract "$img" "${OUTPUT_DIR}/${base}" -l ${MODEL_NAME} lstm.train
done

# Step 3: Create list files
find ${OUTPUT_DIR} -name "*.lstmf" > ${OUTPUT_DIR}/train.list
head -n 80 ${OUTPUT_DIR}/train.list > ${OUTPUT_DIR}/train_80.list
tail -n 20 ${OUTPUT_DIR}/train.list > ${OUTPUT_DIR}/eval.list

# Step 4: Train
echo "Starting training..."
lstmtraining \
  --model_output ${OUTPUT_DIR}/${MODEL_NAME} \
  --continue_from path/to/khm.traineddata \
  --train_listfile ${OUTPUT_DIR}/train_80.list \
  --eval_listfile ${OUTPUT_DIR}/eval.list \
  --traineddata path/to/khm.traineddata \
  --max_iterations ${ITERATIONS}

# Step 5: Combine
echo "Combining final model..."
lstmtraining \
  --stop_training \
  --continue_from ${OUTPUT_DIR}/${MODEL_NAME}_checkpoint \
  --traineddata path/to/khm.traineddata \
  --model_output ${OUTPUT_DIR}/${MODEL_NAME}.traineddata

echo "Training complete! Model: ${OUTPUT_DIR}/${MODEL_NAME}.traineddata"
```

Make it executable:
```bash
chmod +x train_khmer.sh
./train_khmer.sh
```

---

## 📚 Resources

### Official Documentation
- **Tesseract Training Guide**: https://tesseract-ocr.github.io/tessdoc/tess4/TrainingTesseract-4.00.html
- **tesstrain Repository**: https://github.com/tesseract-ocr/tesstrain
- **Language Data**: https://github.com/tesseract-ocr/langdata

### Khmer-Specific Resources
- **KhmerST Dataset**: Scene text dataset with Khmer characters
  - Paper: https://arxiv.org/abs/2410.18277
- **Khmer Fonts**: Use diverse Khmer fonts for training
  - Google Fonts: https://fonts.google.com/?subset=khmer

### Community
- **Tesseract Issues**: https://github.com/tesseract-ocr/tesseract/issues
- **Stack Overflow**: Tag `tesseract-ocr`

---

## ⚠️ Common Issues

### 1. "No such file or directory" errors
- **Fix**: Check all file paths are absolute or relative correctly
- **Fix**: Ensure TESSDATA_PREFIX is set correctly

### 2. "Failed to load language data"
- **Fix**: Verify .traineddata file is in correct location
- **Fix**: Check file permissions

### 3. Poor accuracy after training
- **Fix**: Use more diverse training data
- **Fix**: Increase training iterations
- **Fix**: Use better quality images

### 4. Training takes too long
- **Fix**: Use GPU acceleration (if available)
- **Fix**: Reduce image count for initial testing
- **Fix**: Use fine-tuning instead of training from scratch

---

## 🎯 Tips for Better Results

1. **Start Small**: Test with 10-20 images first
2. **Iterate**: Train → Test → Improve → Repeat
3. **Monitor Loss**: Stop when validation loss stops decreasing
4. **Use Existing Model**: Fine-tune from official `khm.traineddata`
5. **Focus on Errors**: Add more training data for problematic characters
6. **Test Regularly**: Evaluate on real documents during training

---

## 📦 Using Your Custom Model in Flutter

Once you have `khm.traineddata`:

1. **Replace the file**:
   ```bash
   cp output/khm.traineddata assets/tessdata/khm.traineddata
   ```

2. **Update pubspec.yaml** (if size changed significantly):
   ```yaml
   flutter:
     assets:
       - assets/tessdata/khm.traineddata
   ```

3. **Restart app** (full restart, not hot reload)

4. **Test** with your documents

---

## 🔄 Alternative: Use Better Pre-trained Models

Before training, try these pre-trained versions:

```bash
# Fast version (1.4MB) - Good for mobile
curl -L -o assets/tessdata/khm.traineddata \
  "https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/main/khm.traineddata"

# Best accuracy (8.1MB) - Highest quality
curl -L -o assets/tessdata/khm.traineddata \
  "https://raw.githubusercontent.com/tesseract-ocr/tessdata_best/main/khm.traineddata"
```

---

## 💡 When to Train vs Use Pre-trained

**Use Pre-trained if:**
- General Khmer text recognition is sufficient
- You don't have training data
- You want quick results

**Train Custom Model if:**
- You have specific fonts/styles to support
- You need better accuracy for your document types
- You have 100+ high-quality training images
- Pre-trained models don't meet your needs

---

Good luck with your training! 🚀
