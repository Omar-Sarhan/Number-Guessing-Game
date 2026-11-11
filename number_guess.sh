#!/bin/bash

PSQL="psql -X -q --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET_NUMBER=$((RANDOM % 1000 + 1))
NUMBER_OF_GUESSES=0

printf 'Enter your username:\n'
IFS= read -r USERNAME || exit 0

SAFE_USERNAME=${USERNAME//\'/\'\'}

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$SAFE_USERNAME'")

if [[ -z "$USER_ID" ]]
then
  USER_ID=$($PSQL "INSERT INTO users(username) VALUES('$SAFE_USERNAME') RETURNING user_id")
  printf 'Welcome, %s! It looks like this is your first time here.\n' "$USERNAME"
else
  STATS=$($PSQL "SELECT COUNT(*), COALESCE(MIN(guesses), 0) FROM games WHERE user_id = $USER_ID")
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$STATS"
  printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' "$USERNAME" "$GAMES_PLAYED" "$BEST_GAME"
fi

printf 'Guess the secret number between 1 and 1000:\n'

while IFS= read -r GUESS
do
  if [[ ! "$GUESS" =~ ^-?[0-9]+$ ]]
  then
    printf 'That is not an integer, guess again:\n'
    continue
  fi

  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  if [[ "$GUESS" == -* ]]
  then
    GUESS_NUMBER=$((-10#${GUESS#-}))
  else
    GUESS_NUMBER=$((10#$GUESS))
  fi

  if (( GUESS_NUMBER > SECRET_NUMBER ))
  then
    printf "It's lower than that, guess again:\n"
  elif (( GUESS_NUMBER < SECRET_NUMBER ))
  then
    printf "It's higher than that, guess again:\n"
  else
    $PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null

    printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' "$NUMBER_OF_GUESSES" "$SECRET_NUMBER"
    break
  fi
done
