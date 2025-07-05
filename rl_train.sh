#!/bin/bash

python3 stable_baselines3_example.py \
  # --onnx_export_path model.onnx \
  --timesteps 100_000 \
  --num_envs 8 \
  --resume_model_path ./flat_stage/model.onnx
echo "Export complete."