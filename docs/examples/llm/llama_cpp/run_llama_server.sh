echo "1) build and install llama_cpp"
echo "   ./babs.sh -b binfo/llama_cpp.binfo"
echo "2) download model"
echo "    Phi-3-mini-4k-instruct-q4.gguf"
echo "3) Copy it to location"
echo "    ~/models/huggingface/Phi-3-mini-4k-instruct-q4.gguf"
echo "4) load rocm sdk build environment"
echo "    source /opt/rocm_sdk_612/bin/env_rocm.sh"
echo "5) launch llama-server"
echo "    llama-server -m ~/models/huggingface/Phi-3-mini-4k-instruct-q4.gguf -c 2048"
echo "6) open ui to llama-server by opening the web-browser to address"
echo "    http://localhost:8080"
echo "7) type text on browser ui and press send button"
echo "8) check the response message"