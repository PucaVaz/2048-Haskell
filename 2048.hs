module Main where

import System.IO (hSetBuffering, stdin, BufferMode(NoBuffering))
import System.Random (randomRIO)
import Data.List (transpose)

data Movement = Up | Down | Left | Right deriving (Eq, Show)
type Board = [[Int]]

-- Começar o tabuleiro e gerar dois blocos
start :: IO Board
start = addRandomBlock =<< addRandomBlock (replicate 4 (replicate 4 0))

-- Logica para adicionar dois blocos aleatorios
addRandomBlock :: Board -> IO Board
addRandomBlock board
    | null emptyPositions = return board
    | otherwise = do
        index <- randomRIO (0, length emptyPositions - 1)
        num <- randomRIO (1, 10 :: Int)
        let (x, y) = emptyPositions !! index
        let value = if num == 1 then 4 else 2
        return $ updateBoard board x y value
  where
    emptyPositions = [(x, y) | x <- [0..3], y <- [0..3], board !! x !! y == 0]

-- Atualizar uma posição de um block
updateBoard :: Board -> Int -> Int -> Int -> Board
updateBoard board x y value =
    take x board ++
    [take y (board !! x) ++ [value] ++ drop (y + 1) (board !! x)] ++
    drop (x + 1) board

-- Somar núeros iguais
combine :: [Int] -> [Int]
combine = adjustLength . foldr merge [] . filter (/= 0)
  where
    merge x [] = [x]
    merge x (y:ys) | x == y = x * 2 : ys
                   | otherwise = x : y : ys
    adjustLength xs = xs ++ replicate (4 - length xs) 0

-- Loop que checa se o jogo já acabou ou não
gameLoop :: Board -> Int -> IO ()
gameLoop board score = do
    printBoard board
    putStrLn $ "Score: " ++ show score
    case gameOver board of
        Just message -> putStrLn message
        Nothing -> do
            move <- captureMovement
            let newBoard = moveBlocks move board
            let pointsGained = sum (concat newBoard)  -- Teste do score
            if newBoard /= board
                then addRandomBlock newBoard >>= \b -> gameLoop b (score + pointsGained)
                else gameLoop board score

-- Ver se o jogo acabou
gameOver :: Board -> Maybe String
gameOver board
    | 2048 `elem` concat board = Just "Parabens, você ganhou"
    | not (any possibleMove [Up, Down, Main.Left, Main.Right]) = Just "Perdeu, nenhuma possibilidade"
    | otherwise = Nothing
  where
    possibleMove move = moveBlocks move board /= board

-- parte do print  


-- Transformar em string para fazer o print com o espaço
showCell :: Int -> String
showCell 0 = " "  -- Coloca dois espaços na hora de printar
showCell x = padString (show x)

-- espaçamento entre os numeros
padString :: String -> String
padString s = replicate (2 - length s) ' ' ++ s  -- Espaçamento

printBoard :: Board -> IO ()
printBoard board = do
    putStr "\ESC[2J\ESC[2J\n" -- Limpar a tela sem usar biblioteca 
    mapM_ (putStrLn . unwords . map showCell) board

-- Pegar o movimento do jogador
captureMovement :: IO Movement
captureMovement = do
    move <- lookup <$> getChar <*> pure [('w', Up), ('a', Main.Left), ('s', Down), ('d', Main.Right)]
    maybe (putStrLn "Use WASD." >> captureMovement) return move


-- mover o buffer
moveBlocks :: Movement -> Board -> Board
moveBlocks Main.Left = map combine
moveBlocks Main.Right = map (reverse . combine . reverse)
moveBlocks Up = transpose . moveBlocks Main.Left . transpose
moveBlocks Down = transpose . moveBlocks Main.Right . transpose

main :: IO ()
main = do
    hSetBuffering stdin NoBuffering
    putStrLn "bem vindo 2048! Use as r WASD para j."
    start >>= \b -> gameLoop b 0  -- tentativa da pontuação