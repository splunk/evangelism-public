#!/bin/bash

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
while ! pg_isready -h postgres -U worms; do
  sleep 1
done

echo "PostgreSQL is ready. Setting up database..."

# Get dependencies
mix deps.get

# Create database if it doesn't exist
mix ecto.create

# Run migrations
mix ecto.migrate

# Start Phoenix server
echo "Starting Phoenix server..."
mix phx.server