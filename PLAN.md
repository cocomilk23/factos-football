# Game Plan: Volley Shot Survivor

## Risk Tasks

### 1. Curved volley shot feel
- **Why isolated:** The game is only fun if the football feels different from a straight bullet.
- **Approach:** Use a kicked ball velocity plus horizontal curve acceleration. Mouse horizontal aim controls both initial angle and curve direction; medium power keeps the strongest curve, high power flies faster with less bend.
- **Verify:** Aiming left/right visibly bends the ball path, medium-power shots bend more than full-power shots, and the trail makes the curve readable.

### 2. Timing window
- **Why isolated:** The player must wait for the feeder ball instead of firing freely.
- **Approach:** Feed one live ball along a short arc into a strike zone. Release while the ball is near the center for Perfect, within the outer zone for normal, and outside the zone for a whiff.
- **Verify:** Releasing near the zone center shows Perfect Shot and creates a fast accurate kick; releasing early/late shows miss feedback and does not create a strong shot.

## Main Build

Build a Godot 2D survival shooter prototype with a fixed football player, a ball launcher, timed feed balls, hold-to-charge volley shots, curved ball flight, enemies advancing from the top, hit scoring, combo, three lives, game over, and restart.

- **Assets needed:** Current version uses generated PNG assets for the stadium field, player, feeder, ball, enemy variants, hearts, and bottom HUD icons; gameplay effects remain code-driven for fast iteration.
- **Verify:**
  - Player remains fixed near the bottom.
  - Launcher regularly feeds one ball into the strike area.
  - Holding Space or left mouse charges power; releasing attempts a volley.
  - Mouse horizontal position changes direction and curve.
  - Football can destroy enemies and continue through short lines of enemies.
  - Enemies spawn from varied horizontal positions and move toward the player.
  - Reaching enemies remove one life; life zero shows game over.
  - R restarts the game.
  - UI is readable at 1280x720.
