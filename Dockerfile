FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json from the backend folder
COPY backend/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the backend code
COPY backend/ ./

# Expose the port the app runs on
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
