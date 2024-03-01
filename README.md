# Unlost

Semantically search your screen time

Shout out to [txtai](https://github.com/neuml/txtai) and breakdown from [Kevin](https://kevinchen.co/blog/rewind-ai-app-teardown/) which makes building this easier.

# Demo
[​​<img src="https://github.com/Vincent-liuwingsang/unlost/blob/main/demo/thumbnail.png?raw=true" width="100%" >](https://www.loom.com/share/6054377ccf204418b5b743c781d7acae?sid=c20b607f-7749-4fe4-b344-d62d09e8aba1 "Demo in Loom")

# Features

* semantic searching your memory
* filtering with dates/application in natural language

> user interview questions from last week @chrome

* search through meeting transcripts
* copy text from screenshot by cropping
* local/provider llm/agent integration (coming soon, help wanted)
* remote server + storage in the cloud (coming soon, help wanted)

# Quick Start

install [here](https://github.com/Vincent-liuwingsang/unlost.github.io/releases/download/prod/unlost.dmg) and run

# Build locally

1. Recompile python server(only if it has changed)

   > python -m PyInstaller unlost_server.py -D -y --windowed --hidden-import=torch --hidden-import=unlost_server --collect-data torch --collect-data en_core_web_sm --copy-metadata torch --copy-metadata tqdm --copy-metadata regex  --copy-metadata requests --copy-metadata packaging --copy-metadata filelock --copy-metadata numpy --copy-metadata tokenizers --copy-metadata importlib_metadata --copy-metadata huggingface-hub --copy-metadata safetensors --copy-metadata pyyaml --exclude-module skl2onnx --add-data "query_classifier.pickle:."
   >
2. Drag python bundle into XCode Resources and delete old one (only if it has changed)
3. XCode Product > Archive, distribute app, custom, copy app

# How it works

Unlost follows client-server which is unusual for desktop application. This makes it a lot easier to

1. add remote storage/server support which would take a lot of the work off your local machine. battery life yay.
2. add SOTA/experimental AI stuff in python
3. cross platform

The UI is written in SwiftUI which is responsible for rendering the UI and ocr/storing screenshots.

The server is written in python which is responsible for indexing screenshots/OCR results, providing endpoint for semantic searching. A lot of heaving lifting from txtai.

All the data is stored under ~/Documents/UnlostApp.nosync

# Contributing

Please discuss significant code changes in discord to make sure it's ok with other users.

Make your changes in a fork and raise PR to merge in.
