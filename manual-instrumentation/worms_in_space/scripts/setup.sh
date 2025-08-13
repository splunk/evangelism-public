#!/bin/bash
set -e

echo "🚀 Setting up worms_in_space..."

# Backend setup
echo "📦 Installing Elixir dependencies..."
mix deps.get

echo "🗄️ Setting up database..."
mix ecto.create
mix ecto.migrate

# Frontend setup
echo "📦 Installing frontend dependencies..."
cd frontend
npm install

# Generate TypeScript types
echo "🔧 Generating TypeScript types..."
npm run codegen

echo "✅ Setup complete! Run 'docker-compose up' to start the application"