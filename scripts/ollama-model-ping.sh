#!/bin/bash

# Simple script to trigger Ollama to load the model into VRAM
# This sends a single request and discards the output.

MODEL="devstral-small-2:24b"

echo "Warming up Ollama with model: $MODEL..."

curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [{\"role\": \"user\", \"content\": \"hi there\"}],
    \"max_tokens\": 1,
    \"temperature\": 0.0,
    \"stream\": false
  }" > /dev/null

if [ $? -eq 0 ]; then
  echo "Model load triggered successfully."
else
  echo "Error: Failed to reach Ollama on localhost:11434"
  exit 1
fi
