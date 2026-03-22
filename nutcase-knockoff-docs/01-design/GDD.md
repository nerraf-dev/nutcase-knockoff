## **GDD: In a Nutshell Knockoff (Working Title)**

### **1. Introduction**

**THE GAME** is a high-energy, word-based party game where the objective is to guess the answer to a hidden question using as few clues as possible. The question is obscured on the main screen, and players take turns revealing one word at a time. Each reveal ends a player's turn, creating a tense **risk-vs-reward** loop: do you reveal another word to be sure, or guess now before someone else steals the points?

### **2. Game Description**

The game is a local multiplayer experience using a **Mobile-as-Controller** model.

- **The Lobby:** The host launches the Godot application on a primary screen (TV/PC). Players join by navigating to a URL on their mobile browsers and entering a room code.
- **The Round:** A series of nine "sliders" hide a central question. On their turn, a player uses their mobile device to either **Reveal** a slider or **Guess**.
- **The Guessing Mechanic:** If a player chooses to guess, they type their answer on their device.
    - **Direct Hit:** Exact matches or minor typos award points.
    - **The Jury:** If a guess is close but not exact, the "non-frozen" players vote on whether to accept it.
- **The Penalty (The Freeze):** An incorrect guess **freezes** the player until the next question and deducts points from their total score.
    

### **3. Key Features & Mechanics**

- **Fuzzy Logic Adjudication:** Uses a **Levenshtein distance algorithm** to forgive minor spelling errors (e.g., "Shakespear" vs "Shakespeare").
- **Democratic Voting:** Integrates a social element where active players act as the "jury" for ambiguous answers via a Yes/No mobile interface.
- **Pattern-Breaking Questions:** Question syntax is varied so the "reveal order" doesn't provide a predictable grammatical hint to the players.
- **Scoring (Decay Model):** * **Base Value:** Questions are weighted by difficulty (100, 150, or 200 points).
    - **The Decay:** Each slider that hides a word reduces the potential score when revealed.
    - **The Blank Rule:** If a slider revealed contains no text (a "blank"), the player retains their turn and no points are deducted.
    - **Incorrect Guess:** Deducts a flat percentage (e.g. **20%**) of the current round's value.

### **4. Visual Style & Concept**

- **Theme:** A "Hand-drawn / Classroom" aesthetic.
- **Main Board:** A textured background (e.g. green chalkboard or nebula swirls) with high-contrast, numbered sliders featuring a "torn paper" edge.
- **Avatars:** Playful, vector-style animal icons representing each player at the bottom of the screen.
- **Feedback UI:** The "GUESS" button is large, orange, and central on the mobile controller to act as the primary call-to-action.
    
### **5. Technical Specifications**

- **Genre:** Word / Trivia / Party Game.
- **Host Platform:** Built in **Godot**; deployed to PC (Windows/Linux/macOS) or as a WebGL export.
- **Controller Platform:** A lightweight **HTML/JavaScript** web application designed for **Portrait mode** to ensure natural typing.
- **Connectivity:** Real-time communication via **WebSockets**.