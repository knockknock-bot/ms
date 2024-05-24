# Use an official Node.js runtime as a base image
FROM node:18

# Set the working directory in the container
WORKDIR /usr/src/microsoft-rewards-script

# Install necessary packages including jq, cron, gettext-base, and dependencies for Playwright
RUN apt-get update && apt-get install -y \
    jq \
    cron \
    gettext-base \
    xvfb \
    libgbm-dev \
    libnss3 \
    libasound2 \
    libxss1 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy all files from the current directory (repository) to the working directory in the container
COPY . .

# Install application dependencies
RUN npm install

# Build the script
RUN npm run build

# Install Playwright Chromium
RUN npx playwright install chromium

# Copy cron file to cron directory
COPY src/crontab.template /etc/cron.d/microsoft-rewards-cron.template

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Define the command to run your application with cron optionally
CMD sh -c 'echo "$TZ" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata && if [ "$RUN_ON_START" = "true" ]; then npm start; fi && envsubst < /etc/cron.d/microsoft-rewards-cron.template > /etc/cron.d/microsoft-rewards-cron && crontab /etc/cron.d/microsoft-rewards-cron && cron && tail -f /var/log/cron.log'
