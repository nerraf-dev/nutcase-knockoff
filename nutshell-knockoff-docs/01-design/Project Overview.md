
Project: In a Nutshell Digital. Core concepts involve a game loop where players uncover words to guess the answer, with a pot that reduces as words are revealed. Modes include 'Around' and 'Hide'. The technical stack uses Godot 4.x with a Jackbox-style architecture over WebSockets.



Multiplayer game. Game runs on the computer (or mobile device). Thinking 'Jackbox' style and using mobile devices as remotes. 


Select number of rounds (min 3, max...25?) *or* 'first to n', 3, 5, 10, PYO.

Theres either a score pot - based on words available (I'm thinking)

Players take it in turns to either **reveal a word** or **guess the answer**. 
- If they **reveal** a word the score pot reduces.
- If they choose **guess**
	- Thinking two options, but not sure how to implement
		- Couch play (or a stream) - They say the answer to the group. 
			- The player hit reveal and gets to see the correct answer on their device. 
				- If the they answered incorrectly - they reject the answer, they are frozen out of the game, they loose points, the game continues with the rest of the players. If only 1 player remains they get a free reveal and guess.
				- If they answer correctly, they accept the answer. They get the points. The answer is then shown to the remaining players. They can challenge the outcome. E.g. in the case of the player answering 'blue' but it should be 'pink', but accepted the answer anyway another player or players can challenge this and remaining players can choose to deduct points from the player.
		- All modes (but particularly when speech is harder) - Type an answer
			- In the even the player chooses to guess, the Answer is typed 
				- Answer is shown to all players
				- Players gets to see the answer and then accept or reject.
				- In the case of accepting their typed answer, this and the answer is displayed to the players to challenge.
- In the case of winning, they get the pot the next question comes along.


Plan to use Godot (current 4.5.1)
Questions:
- categories
- tags
- language (?)