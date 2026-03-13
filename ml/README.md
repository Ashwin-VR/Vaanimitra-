# Vanimitra ML Pipeline

Owner: Dev 1. Do not modify from lib/ side.

## Quick start
1. python data/dataset_gen.py           → vanimitra_train.jsonl
2. python data/whisper_aug.py           → adds mishearing noise
3. python training/sagemaker_launch.py  → starts ml.g4dn.xlarge job
4. bash pipeline/post_training_pipeline.sh → GGUF to USB
