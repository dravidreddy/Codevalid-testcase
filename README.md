# Testing Codevalid - Chatbot Application

A simple, lightweight conversational chatbot application used for testing Codevalid onboarding, feature breakdown, and automated test generation workflows.

## Overview
This is a repository containing a full-stack chatbot with a Python FastAPI backend and a responsive glassmorphic HTML/JS frontend.

## Features

### Chatbot Messaging Feature
The chatbot provides conversational responses based on user input.

- **Greeting Handling**: When the user sends greetings like "hi", "hello", "hey", or "hullo", the chatbot responds with "Hello! How can I help you today?".
- **Assistance Inquiry**: When the user asks for help or inquires about capabilities, the chatbot responds with instructions and support information.
- **Identity Inquiry**: When the user asks "who are you" or "what are you", the chatbot introduces itself as a testing chatbot built for Codevalid.
- **Fallback Echo Response**: For any unhandled messages, the chatbot returns an echo response acknowledging the user's input.
- **Chat History Management**: The system displays messages in a chat conversation window and allows clearing conversation history via a "Clear Chat" button.

## How to Run

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Start the application:
   ```bash
   python app.py
   ```
3. Open `http://localhost:8000` in your web browser.
