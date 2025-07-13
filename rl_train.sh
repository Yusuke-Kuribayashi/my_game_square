#!/bin/bash

python3 stable_baselines3_example.py \
  --timesteps 1_000_000 \
  --resume_model_path ./jump_model.zip \
  # --onnx_export_path model.onnx \
  # --save_model_path ./jump_model.zip \
  # --num_envs 8 \
echo "Export complete."