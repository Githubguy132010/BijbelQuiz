# BijbelQuiz API CLI

A command-line interface for interacting with the BijbelQuiz local API, including an interactive quiz game mode.

**Note: This is a proof-of-concept (PoC) utility for testing and demonstrating the BijbelQuiz API functionality. It is not intended for production use.**

## Installation

1. Create a virtual environment (optional but recommended):
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Make the script executable:
```bash
chmod +x bijbelquiz_cli.py
```

## Usage

All commands require an API key. You can get this from the BijbelQuiz app settings.

### Basic Syntax

```bash
# Activate virtual environment first
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Then run the CLI
python bijbelquiz_cli.py --api-key YOUR_API_KEY COMMAND [OPTIONS]
```

### Available Commands

#### Health Check
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY health
```

#### Get Questions
```bash
# Get 10 random questions
python bijbelquiz_cli.py --api-key YOUR_API_KEY questions

# Get questions from Genesis category
python bijbelquiz_cli.py --api-key YOUR_API_KEY questions --category Genesis

# Get 5 hard questions
python bijbelquiz_cli.py --api-key YOUR_API_KEY questions --limit 5 --difficulty 4
```

#### Get User Progress
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY progress
```

#### Get Game Statistics
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY stats
```

#### Get App Settings
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY settings
```

#### Star Management

##### Get Star Balance
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY stars balance
```

##### Add Stars
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY stars add 10 "Quiz completed" --lesson-id lesson_1
```

##### Spend Stars
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY stars spend 5 "Skip question"
```

##### Get Star Transactions
```bash
# Get last 20 transactions
python bijbelquiz_cli.py --api-key YOUR_API_KEY stars transactions --limit 20

# Get only earned transactions
python bijbelquiz_cli.py --api-key YOUR_API_KEY stars transactions --type earned
```

##### Get Star Statistics
```bash
python bijbelquiz_cli.py --api-key YOUR_API_KEY stars stats
```

#### Interactive Quiz Game
Play the BijbelQuiz directly in your terminal!

```bash
# Start a 10-question game (default)
python bijbelquiz_cli.py --api-key YOUR_API_KEY game

# Play 5 questions from Genesis category
python bijbelquiz_cli.py --api-key YOUR_API_KEY game --category Genesis --questions 5

# Play hard questions only (difficulty 4-5)
python bijbelquiz_cli.py --api-key YOUR_API_KEY game --difficulty 4

# Play 20 questions with max difficulty
python bijbelquiz_cli.py --api-key YOUR_API_KEY game --questions 20 --difficulty 5
```

**Game Features:**
- 🎮 Interactive terminal-based quiz experience
- ⭐ Earn stars for correct answers (automatically added to your balance)
- 🏆 Score tracking with difficulty-based points
- 📊 Real-time statistics and final results
- 📖 Biblical references and category filtering
- ⌨️ Easy keyboard navigation (Ctrl+C to quit anytime)

**Scoring System:**
- Points: difficulty level × 10 points per correct answer
- Stars: difficulty level stars per correct answer
- Example: A difficulty 3 question = 30 points + 3 stars

### Custom API URL

If your API is running on a different port or host:
```bash
python bijbelquiz_cli.py --url http://localhost:8080/v1 --api-key YOUR_API_KEY health
```

## Examples

### Check API Health
```bash
$ python bijbelquiz_cli.py --api-key bq_abc123 health
{
  "status": "healthy",
  "timestamp": "2025-10-20T16:45:49.539Z",
  "service": "BijbelQuiz API",
  "version": "v1",
  "uptime": "running"
}
```

### Get Questions
```bash
$ python bijbelquiz_cli.py --api-key bq_abc123 questions --category Genesis --limit 3
{
  "questions": [
    {
      "question": "Wie bouwde de ark?",
      "correctAnswer": "Noach",
      "incorrectAnswers": ["Abraham", "Mozes", "David"],
      "difficulty": 2,
      "type": "mc",
      "categories": ["Genesis"],
      "biblicalReference": "Genesis 6",
      "allOptions": ["Noach", "Abraham", "Mozes", "David"],
      "correctAnswerIndex": 0
    }
  ],
  "count": 1,
  "category": "Genesis",
  "difficulty": null,
  "timestamp": "2025-10-20T16:45:49.539Z",
  "processing_time_ms": 45
}
```

### Add Stars
```bash
$ python bijbelquiz_cli.py --api-key bq_abc123 stars add 10 "Daily bonus"
{
  "success": true,
  "balance": 1260,
  "amount_added": 10,
  "reason": "Daily bonus",
  "timestamp": "2025-10-20T16:45:49.539Z",
  "processing_time_ms": 15
}
```

### Play Interactive Quiz Game
```bash
$ python bijbelquiz_cli.py --api-key bq_abc123 game --category Genesis --questions 5

Starting BijbelQuiz game...
Press Ctrl+C at any time to quit.
✅ Loaded 5 questions!

============================================================
                    🏛️ BIJBEL QUIZ GAME
============================================================

📊 Score: 0 | Correct: 0/0 | Stars: 0
------------------------------------------------------------

📖 Question 1:
Wie bouwde de ark?
📚 Bible Reference: Genesis 6
📂 Categories: Genesis
🎯 Difficulty: ⭐⭐

Choices:
  1. Abraham
  2. Noach
  3. Mozes
  4. David

Enter your choice (1-4): 2

🎉 CORRECT!
✅ Your answer: Noach
⭐ You earned 20 points and 2 stars!

============================================================
                    🏛️ BIJBEL QUIZ GAME
============================================================

📊 Score: 20 | Correct: 1/1 | Stars: 2
------------------------------------------------------------

📖 Question 2:
Wie was de eerste koning van Israel?
📚 Bible Reference: 1 Samuel 10
📂 Categories: 1 Samuel
🎯 Difficulty: ⭐⭐⭐

Choices:
  1. Saul
  2. David
  3. Salomo
  4. Samuel

...continues with interactive gameplay...

============================================================
                      🏆 GAME COMPLETE!
============================================================

📊 Final Results:
   • Questions answered: 5
   • Correct answers: 4
   • Accuracy: 80.0%
   • Total score: 90
   • Stars earned: 9
   • New star balance: 1269

Thank you for playing! 🙏
```

## Error Handling

The CLI provides clear error messages for common issues:

- **Connection errors**: Check if the API server is running
- **Authentication errors**: Verify your API key
- **Rate limiting**: Wait before retrying (check Retry-After header)
- **Invalid parameters**: Check command syntax and parameter values

## Requirements

- Python 3.6+
- Virtual environment (optional but recommended)
- No external dependencies required (uses only Python standard library)

## Notes

This is a proof-of-concept CLI utility designed for:
- Testing API endpoints during development
- Demonstrating API functionality
- Quick API interaction for debugging
- **NEW:** Interactive quiz gaming experience directly in the terminal

For production use, consider:
- Better error handling
- Configuration file support
- Enhanced interactive features
- Output formatting options
- Authentication token management