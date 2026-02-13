#!/bin/bash

# Clone Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1 -b stable

# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Create .env file from Vercel environment variables
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# Build Flutter web
flutter build web --release