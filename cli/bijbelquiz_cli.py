#!/usr/bin/env python3
"""
BijbelQuiz API CLI - Proof of Concept

A command-line interface for interacting with the BijbelQuiz local API.
"""

import argparse
import json
import sys
import urllib.request
import urllib.parse
import urllib.error
import time
import random
from typing import Optional
from dataclasses import dataclass


class BijbelQuizAPI:
    """Client for the BijbelQuiz local API."""

    def __init__(self, base_url: str = "http://localhost:7777/v1", api_key: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.headers = {"Content-Type": "application/json"}
        if api_key:
            self.headers.update({"X-API-Key": api_key})

    def _get(self, endpoint: str, params: Optional[dict] = None) -> dict:
        """Make a GET request to the API."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        if params:
            url += "?" + urllib.parse.urlencode(params)
        
        try:
            request = urllib.request.Request(url, headers=self.headers)
            with urllib.request.urlopen(request) as response:
                return json.loads(response.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            print(f"Error: {e}", file=sys.stderr)
            try:
                error_data = json.loads(e.read().decode('utf-8'))
                print(f"API Error: {error_data.get('error', 'Unknown error')}", file=sys.stderr)
                print(f"Message: {error_data.get('message', '')}", file=sys.stderr)
            except:
                print(f"HTTP {e.code}: {e.reason}", file=sys.stderr)
            sys.exit(1)
        except urllib.error.URLError as e:
            print(f"URL Error: {e.reason}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Unexpected error: {e}", file=sys.stderr)
            sys.exit(1)

    def _post(self, endpoint: str, data: dict) -> dict:
        """Make a POST request to the API."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            json_data = json.dumps(data).encode('utf-8')
            request = urllib.request.Request(url, data=json_data, headers=self.headers, method='POST')
            with urllib.request.urlopen(request) as response:
                return json.loads(response.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            print(f"Error: {e}", file=sys.stderr)
            try:
                error_data = json.loads(e.read().decode('utf-8'))
                print(f"API Error: {error_data.get('error', 'Unknown error')}", file=sys.stderr)
                print(f"Message: {error_data.get('message', '')}", file=sys.stderr)
            except:
                print(f"HTTP {e.code}: {e.reason}", file=sys.stderr)
            sys.exit(1)
        except urllib.error.URLError as e:
            print(f"URL Error: {e.reason}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Unexpected error: {e}", file=sys.stderr)
            sys.exit(1)

    def health(self) -> dict:
        """Check API health."""
        return self._get("health")

    def get_questions(self, category: Optional[str] = None, limit: int = 10, difficulty: Optional[int] = None) -> dict:
        """Get quiz questions."""
        params = {"limit": limit}
        if category:
            params["category"] = category
        if difficulty:
            params["difficulty"] = difficulty
        return self._get("questions", params)

    def get_progress(self) -> dict:
        """Get user progress."""
        return self._get("progress")

    def get_stats(self) -> dict:
        """Get game statistics."""
        return self._get("stats")

    def get_settings(self) -> dict:
        """Get app settings."""
        return self._get("settings")

    def get_star_balance(self) -> dict:
        """Get star balance."""
        return self._get("stars/balance")

    def add_stars(self, amount: int, reason: str, lesson_id: Optional[str] = None) -> dict:
        """Add stars to balance."""
        data = {"amount": amount, "reason": reason}
        if lesson_id:
            data["lessonId"] = lesson_id
        return self._post("stars/add", data)

    def spend_stars(self, amount: int, reason: str, lesson_id: Optional[str] = None) -> dict:
        """Spend stars from balance."""
        data = {"amount": amount, "reason": reason}
        if lesson_id:
            data["lessonId"] = lesson_id
        return self._post("stars/spend", data)

    def get_star_transactions(self, limit: int = 50, type_filter: Optional[str] = None, lesson_id: Optional[str] = None) -> dict:
        """Get star transactions."""
        params = {"limit": limit}
        if type_filter:
            params["type"] = type_filter
        if lesson_id:
            params["lessonId"] = lesson_id
        return self._get("stars/transactions", params)

    def get_star_stats(self) -> dict:
        """Get star statistics."""
        return self._get("stars/stats")


@dataclass
class QuizQuestion:
    """Represents a quiz question."""
    question: str
    correctAnswer: str
    incorrectAnswers: list
    difficulty: int
    type: str
    categories: list
    biblicalReference: str
    allOptions: list
    correctAnswerIndex: int


class QuizGame:
    """Interactive quiz game."""
    
    def __init__(self, api: BijbelQuizAPI):
        self.api = api
        self.score = 0
        self.total_questions = 0
        self.correct_answers = 0
        self.stars_earned = 0
        self.start_time = None
        
    def clear_screen(self):
        """Clear the terminal screen."""
        print("\n" * 50)
        
    def print_header(self, title: str):
        """Print a formatted header."""
        print("=" * 60)
        print(f"{title:^60}")
        print("=" * 60)
        
    def print_score(self):
        """Print current score."""
        print(f"\n📊 Score: {self.score} | Correct: {self.correct_answers}/{self.total_questions} | Stars: {self.stars_earned}")
        print("-" * 60)
        
    def get_user_input(self, prompt: str, valid_choices: list = None) -> str:
        """Get user input with validation."""
        while True:
            try:
                user_input = input(prompt).strip().lower()
                if valid_choices and user_input not in valid_choices:
                    print(f"Please enter one of: {', '.join(valid_choices)}")
                    continue
                return user_input
            except KeyboardInterrupt:
                print("\n\nGame interrupted by user.")
                sys.exit(0)
                
    def display_question(self, question_data: dict):
        """Display a quiz question."""
        question = QuizQuestion(**question_data)
        self.clear_screen()
        self.print_header("🏛️ BIJBEL QUIZ GAME")
        self.print_score()
        
        print(f"\n📖 Question {self.total_questions + 1}:")
        print(f"{question.question}")
        
        if question.biblicalReference:
            print(f"📚 Bible Reference: {question.biblicalReference}")
            
        if question.categories:
            print(f"📂 Categories: {', '.join(question.categories)}")
            
        # Convert difficulty to int to avoid string multiplication error
        difficulty = int(question.difficulty) if isinstance(question.difficulty, str) else question.difficulty
        print(f"\n🎯 Difficulty: {'⭐' * difficulty}")
        print("\nChoices:")
        
        # Display all options
        for i, option in enumerate(question.allOptions, 1):
            print(f"  {i}. {option}")
            
        return question
        
    def play_round(self, question_data: dict) -> bool:
        """Play a single question round."""
        question = self.display_question(question_data)
        
        # Get user choice
        valid_choices = [str(i) for i in range(1, len(question.allOptions) + 1)]
        choice = self.get_user_input(f"\nEnter your choice (1-{len(question.allOptions)}): ", valid_choices)
        
        user_answer_index = int(choice) - 1
        user_answer = question.allOptions[user_answer_index]
        correct_answer = question.correctAnswer
        
        # Check if answer is correct
        is_correct = user_answer_index == question.correctAnswerIndex
        
        # Convert difficulty to int to avoid string multiplication error
        difficulty = int(question.difficulty) if isinstance(question.difficulty, str) else question.difficulty
        
        # Calculate points and stars
        points = difficulty * 10
        stars_earned = difficulty if is_correct else 0
        
        # Update stats
        self.total_questions += 1
        if is_correct:
            self.correct_answers += 1
            self.score += points
            self.stars_earned += stars_earned
            
        # Show result
        self.clear_screen()
        self.print_header("🏛️ BIJBEL QUIZ GAME")
        
        if is_correct:
            print("🎉 CORRECT!")
            print(f"✅ Your answer: {user_answer}")
            print(f"⭐ You earned {points} points and {stars_earned} stars!")
        else:
            print("❌ INCORRECT!")
            print(f"❌ Your answer: {user_answer}")
            print(f"✅ Correct answer: {correct_answer}")
            
        if question.biblicalReference:
            print(f"\n📚 Bible Reference: {question.biblicalReference}")
            
        # Brief pause before next question
        time.sleep(2)
        
        return is_correct
        
    def end_game(self):
        """End the game and show final results."""
        self.clear_screen()
        self.print_header("🏆 GAME COMPLETE!")
        
        accuracy = (self.correct_answers / self.total_questions * 100) if self.total_questions > 0 else 0
        
        print(f"📊 Final Results:")
        print(f"   • Questions answered: {self.total_questions}")
        print(f"   • Correct answers: {self.correct_answers}")
        print(f"   • Accuracy: {accuracy:.1f}%")
        print(f"   • Total score: {self.score}")
        print(f"   • Stars earned: {self.stars_earned}")
        
        # Award stars via API
        if self.stars_earned > 0:
            try:
                result = self.api.add_stars(
                    self.stars_earned,
                    f"Quiz game completed - {self.correct_answers}/{self.total_questions} correct"
                )
                if result.get('success'):
                    print(f"   • New star balance: {result.get('balance', 'Unknown')}")
                else:
                    print(f"   • Warning: Could not update star balance")
            except Exception as e:
                print(f"   • Warning: Could not award stars - {e}")
                
        print("\nThank you for playing! 🙏")
        
    def start(self, category: str = None, difficulty: int = None, num_questions: int = 10):
        """Start the quiz game."""
        print("Starting BijbelQuiz game...")
        print("Press Ctrl+C at any time to quit.")
        time.sleep(2)
        
        self.start_time = time.time()
        
        try:
            # Get questions from API
            print("Loading questions...")
            result = self.api.get_questions(category=category, limit=num_questions, difficulty=difficulty)
            
            if 'questions' not in result or not result['questions']:
                print("❌ No questions available. Please check your API connection and try again.")
                return
                
            questions = result['questions']
            print(f"✅ Loaded {len(questions)} questions!")
            time.sleep(1)
            
            # Play each question
            for i, question_data in enumerate(questions, 1):
                if not self.play_round(question_data):
                    # Allow user to continue or quit on wrong answer
                    if i < len(questions):
                        continue_game = self.get_user_input(
                            "\nContinue playing? (y/n): ", ['y', 'n', 'yes', 'no']
                        )
                        if continue_game in ['n', 'no']:
                            break
                            
            # End game
            self.end_game()
            
        except KeyboardInterrupt:
            print("\n\nGame interrupted. Final results:")
            self.end_game()
        except Exception as e:
            print(f"\n❌ Error during game: {e}")
            print("Please check your API connection and try again.")


def print_json(data: dict):
    """Pretty print JSON data."""
    print(json.dumps(data, indent=2, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description="BijbelQuiz API CLI")
    parser.add_argument("--url", default="http://localhost:7777/v1", help="API base URL")
    parser.add_argument("--api-key", required=True, help="API key for authentication")

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Health command
    subparsers.add_parser("health", help="Check API health")

    # Questions command
    questions_parser = subparsers.add_parser("questions", help="Get quiz questions")
    questions_parser.add_argument("--category", help="Filter by category")
    questions_parser.add_argument("--limit", type=int, default=10, help="Number of questions")
    questions_parser.add_argument("--difficulty", type=int, choices=range(1, 6), help="Difficulty level (1-5)")

    # Progress command
    subparsers.add_parser("progress", help="Get user progress")

    # Stats command
    subparsers.add_parser("stats", help="Get game statistics")

    # Game command
    game_parser = subparsers.add_parser("game", help="Start interactive quiz game")
    game_parser.add_argument("--category", help="Filter by category")
    game_parser.add_argument("--difficulty", type=int, choices=range(1, 6), help="Difficulty level (1-5)")
    game_parser.add_argument("--questions", type=int, default=10, help="Number of questions to play (default: 10)")

    # Settings command
    subparsers.add_parser("settings", help="Get app settings")

    # Stars subcommands
    stars_parser = subparsers.add_parser("stars", help="Star management commands")
    stars_subparsers = stars_parser.add_subparsers(dest="stars_command", help="Star commands")

    # Stars balance
    stars_subparsers.add_parser("balance", help="Get star balance")

    # Stars add
    add_parser = stars_subparsers.add_parser("add", help="Add stars")
    add_parser.add_argument("amount", type=int, help="Amount of stars to add")
    add_parser.add_argument("reason", help="Reason for adding stars")
    add_parser.add_argument("--lesson-id", help="Lesson ID")

    # Stars spend
    spend_parser = stars_subparsers.add_parser("spend", help="Spend stars")
    spend_parser.add_argument("amount", type=int, help="Amount of stars to spend")
    spend_parser.add_argument("reason", help="Reason for spending stars")
    spend_parser.add_argument("--lesson-id", help="Lesson ID")

    # Stars transactions
    transactions_parser = stars_subparsers.add_parser("transactions", help="Get star transactions")
    transactions_parser.add_argument("--limit", type=int, default=50, help="Number of transactions")
    transactions_parser.add_argument("--type", choices=["earned", "spent", "lesson_reward", "refund"], help="Filter by transaction type")
    transactions_parser.add_argument("--lesson-id", help="Filter by lesson ID")

    # Stars stats
    stars_subparsers.add_parser("stats", help="Get star statistics")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    api = BijbelQuizAPI(args.url, args.api_key)

    try:
        if args.command == "health":
            result = api.health()
            print_json(result)

        elif args.command == "questions":
            result = api.get_questions(args.category, args.limit, args.difficulty)
            print_json(result)

        elif args.command == "progress":
            result = api.get_progress()
            print_json(result)

        elif args.command == "stats":
            result = api.get_stats()
            print_json(result)

        elif args.command == "game":
            game = QuizGame(api)
            game.start(
                category=args.category,
                difficulty=args.difficulty,
                num_questions=args.questions
            )

        elif args.command == "settings":
            result = api.get_settings()
            print_json(result)

        elif args.command == "stars":
            if args.stars_command == "balance":
                result = api.get_star_balance()
                print_json(result)

            elif args.stars_command == "add":
                result = api.add_stars(args.amount, args.reason, args.lesson_id)
                print_json(result)

            elif args.stars_command == "spend":
                result = api.spend_stars(args.amount, args.reason, args.lesson_id)
                print_json(result)

            elif args.stars_command == "transactions":
                result = api.get_star_transactions(args.limit, args.type, args.lesson_id)
                print_json(result)

            elif args.stars_command == "stats":
                result = api.get_star_stats()
                print_json(result)

            else:
                stars_parser.print_help()

        else:
            parser.print_help()

    except KeyboardInterrupt:
        print("\nOperation cancelled", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()