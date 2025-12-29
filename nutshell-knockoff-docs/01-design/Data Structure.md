
JSON Question Schema for the game. Includes fields for id, type, text, answer, starting_pot, and category.


### The Player Object

Each player needs a unique identifier so the server knows who is "Buzzing in."

- **`id`**: (int/string) The unique network ID.
- **`name`**: (string) The display name chosen.
- **`score`**: (int) Their total game points.
- **`is_active`**: (bool) Is it currently their turn? 
- **`connection_status`**: (bool) Useful for handling people whose phones go to sleep.

