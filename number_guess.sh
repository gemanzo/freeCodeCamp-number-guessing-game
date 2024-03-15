#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number
RANDOM_NUMBER=$((1 + RANDOM % 1000))

# Prompt the user to enter the name
echo "Enter your username:"
read USERNAME

# Check if the user exists and get user_id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")

if [[ -z $USER_ID ]]
then
  # Insert the new user into the database and retrieve the new user_id
  $($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  # Get the count of the games played and the best game with fewer attempts
  GAMES_COUNT=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID;")
  BEST_GAME=$($PSQL "SELECT MIN(attempts) FROM games WHERE user_id = $USER_ID;")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_COUNT games, and your best game took $BEST_GAME guesses."
fi

# Start a new game
$($PSQL "INSERT INTO games(user_id, attempts) VALUES($USER_ID, 0);")
GAME_ID=$($PSQL "SELECT MAX(game_id) FROM games WHERE user_id = $USER_ID;")

echo -e "\nGuess the secret number between 1 and 1000:"
ATTEMPTS=0
while true
do
  read GUESS
  ATTEMPTS=$((ATTEMPTS + 1))
  
  # Check if the guess is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo -e "That is not an integer, guess again:"
    continue
  fi
  
  # Check if the guess is correct
  if [[ $GUESS -eq $RANDOM_NUMBER ]]; then
    echo -e "You guessed it in $ATTEMPTS tries. The secret number was $RANDOM_NUMBER. Nice job!"
    # Update the game record with the final attempt count
    $($PSQL "UPDATE games SET attempts = $ATTEMPTS WHERE game_id = $GAME_ID;")
    break
  elif [[ $GUESS -gt $RANDOM_NUMBER ]]; then
    echo -e "It's lower than that, guess again:"
  else
    echo -e "It's higher than that, guess again:"
  fi
done
