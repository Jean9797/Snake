module SnakeMoveEngine
    ( update
    , handleKeys
    ) where

import Graphics.Gloss
import Graphics.Gloss.Data.ViewPort
import Graphics.Gloss.Interface.Pure.Game

import SnakeGameState
import SnakeRandomGenerator

-- | Update the game by moving the snake and react properly to a situation.
update :: Float -> SnakeGame -> SnakeGame
update seconds = randomFoodPosition . selfBounce . wallBounce . moveSnake seconds

-- | Update the snake position using its current moveDirection.
moveSnake :: Float    -- ^ The number of seconds since last update
         -> SnakeGame -- ^ The initial game state
         -> SnakeGame -- ^ A new game state with an updated snake position
moveSnake seconds game = if counter < 60 then game { fpsCounter = if length s < 15 then counter + length s else counter + 15 }
    else game { snake = s', fpsCounter = 0 }
  where
    -- Current state of fpsCounter.
    counter = fpsCounter game

    -- Old snake and direction.
    direction = moveDirection game

    -- Old snake positions.
    s = snake game

    -- Current food position.
    fp = foodPosition game

    --New head of the snake.
    newHead = getPointAfterMove direction $ head s

    -- New snake. If we have just eat something, we grow up.
    s' = if fp == newHead then newHead : s else init $ newHead : s

    -- Converts point and moveDirection to new point after move.
    getPointAfterMove :: MoveDirection -> Position -> Position
    getPointAfterMove d (x, y) = case d of
        Upp -> (x, y+size)
        Downn -> (x, y-size)
        Leftt -> (x-size, y)
        Rightt -> (x+size, y)

-- | Detect a collision with snake himself.
selfBounce :: SnakeGame -> SnakeGame
selfBounce game = if selfCollision s then error "You hit yourself." else game
    where
        -- Current snake.
        s = snake game

-- | Detect a collision with one of the side walls.
wallBounce :: SnakeGame -> SnakeGame
wallBounce game = if wallCollision h then error "You hit the wall." else game
  where
    -- Current head position.
    h = head $ snake game

-- | Given position return whether a collision with walls occurred.
wallCollision :: Position -> Bool 
wallCollision (x, y) = topCollision || bottomCollision || leftCollision || rightCollision
  where
    topCollision    = y - size `quot` 2 <= -height `quot` 2 
    bottomCollision = y + size `quot` 2 >=  height `quot` 2
    leftCollision   = x - size `quot` 2 <= -width `quot` 2
    rightCollision  = x + size `quot` 2 >=  width `quot` 2

-- | Given snake return whether a collision occurred.
selfCollision :: [Position] -> Bool 
selfCollision (x:xs) = iterateOverSnake x xs
  where
    -- Iterates over tail of the snake and find for collision.
    iterateOverSnake :: Position -> [Position] -> Bool
    iterateOverSnake _ [] = False
    iterateOverSnake p (y:ys) = if p == y then True else False || iterateOverSnake p ys


-- | Respond to key events.
handleKeys :: Event -> SnakeGame -> SnakeGame

-- For an arrows keypress, set moveDirection into proper direction.
handleKeys (EventKey (SpecialKey arrow) Down _ _) game = case arrow of
    KeyUp -> if Upp == bannedMoveDirection then game else game { moveDirection = Upp }
    KeyDown -> if Downn == bannedMoveDirection then game else game { moveDirection = Downn }
    KeyLeft -> if Leftt == bannedMoveDirection then game else game { moveDirection = Leftt }
    KeyRight -> if Rightt == bannedMoveDirection then game else game { moveDirection = Rightt }
    where
        -- Positions of snake on the map.
        snakePositions = snake game

        -- Move direction which will wipe out your game.
        bannedMoveDirection = convertPositionsToMoveDirection (snakePositions !! 1) (head snakePositions)

-- Do nothing for all other events.
handleKeys _ game = game

-- Convert 2 points into move direction.
convertPositionsToMoveDirection :: Position -> Position -> MoveDirection
convertPositionsToMoveDirection (x1, y1) (x2, y2)
    | x1 == x2 + size && y1 == y2 = Rightt
    | x1 == x2 - size && y1 == y2 = Leftt
    | x1 == x2 && y1 == y2 + size = Upp
    | x1 == x2 && y1 == y2 - size = Downn
    | otherwise = error "Faile with converting 2 points into move direction."