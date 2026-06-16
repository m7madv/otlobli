FROM node:20-slim

RUN apt-get update && apt-get install -y wget ca-certificates --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./

# Install npm packages without running postinstall (to control browser install separately)
RUN npm install --ignore-scripts

# Install Chromium with all system dependencies explicitly
RUN npx playwright install chromium --with-deps

COPY src/ ./src/

ENV NODE_ENV=production
EXPOSE 3001

CMD ["node", "src/index.js"]
