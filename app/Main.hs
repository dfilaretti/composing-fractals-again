module Main (main) where

import Codec.Picture qualified as P
import Codec.Picture.Types (createMutableImage, unsafeFreezeImage, writePixel)

{---------------------------------------------------------------------------
  Types
----------------------------------------------------------------------------}

type Point = (Float, Float)

type Image color = Point -> color

type Grid a = [[a]]

{---------------------------------------------------------------------------
  Main function...

  Ouch... no real main function here!!
  This is a project to be experienced on the REPL - `cabal repl` should
  do the trick!
----------------------------------------------------------------------------}

main :: IO ()
main = putStrLn "Hello, Haskell!"

{---------------------------------------------------------------------------
  Functions

  This is all based on the "Composing Fractals" Functional Pearl
  (https://www.cambridge.org/core/journals/journal-of-functional-programming/article/functional-pearl-composing-fractals/EBF5B1EBB717AFEC0CA84FE8A07C5C24)

  So I'm not going to repeat it all here :)
----------------------------------------------------------------------------}

-- TODO: do this with complex numbers instead!
next :: Point -> Point -> Point
next (u, v) (x, y) =
  (x ** 2 - y ** 2 + u, 2 * x * y + v)

mandelbrot :: Point -> [Point]
mandelbrot p = iterate (next p) (0, 0)

julia :: Point -> Point -> [Point]
julia c = iterate (next c)

fairlyClose :: Point -> Bool
fairlyClose (u, v) = u ** 2 + v ** 2 < 100

inMandelbrotSet :: Point -> Bool
inMandelbrotSet p = all fairlyClose (mandelbrot p)

approxTest :: Int -> Point -> Bool
approxTest n p =
  all fairlyClose (take n (mandelbrot p))

chooseColor :: [color] -> [Point] -> color
chooseColor palette =
  (palette !!) . length . take n . takeWhile fairlyClose
  where
    n = length palette - 1

fracImage :: (Point -> [Point]) -> [color] -> Image color
fracImage fractal palette =
  chooseColor palette . fractal

rectCoords :: Point -> Float -> Int -> Int -> (Point, Point)
rectCoords center radius cols rows =
  adjustSquareToAspectRatio cols rows $ squareCoords center radius

squareCoords :: Point -> Float -> (Point, Point)
squareCoords (x, y) radius =
  ((xMinS, yMinS), (xMaxS, yMaxS))
  where
    xMinS = x - radius
    yMinS = y - radius
    xMaxS = x + radius
    yMaxS = y + radius

-- TODO: this is ugly, should probably refactor
adjustSquareToAspectRatio :: Int -> Int -> (Point, Point) -> (Point, Point)
adjustSquareToAspectRatio cols rows xs@((xMin, yMin), (xMax, yMax))
  | rows > cols =
      let ratio = fromIntegral rows / fromIntegral cols
          r = ratio - 1
          delta = (h * r) / 2
       in ((xMin, yMin - delta), (xMax, yMax + delta))
  | cols > rows =
      let ratio = fromIntegral cols / fromIntegral rows
          r = ratio - 1
          delta = (w * r) / 2
       in ((xMin - delta, yMin), (xMax + delta, yMax))
  | otherwise = xs
  where
    w = xMax - xMin
    h = yMax - yMin

-- This version wasn't on the paper, it's made so that we can
-- specify a portion of the Mandelbrot/Julia set via a centre point
-- and a radius instead of two points (as in the original paper)
grid' :: Int -> Int -> Point -> Float -> Grid Point
grid' cols rows centre radius =
  grid cols rows p1 p2
  where
    (p1, p2) = rectCoords centre radius cols rows

grid :: Int -> Int -> Point -> Point -> Grid Point
grid c r (xMin, yMin) (xMax, yMax) =
  [[(x, y) | x <- for c xMin xMax] | y <- for r yMin yMax]

for :: Int -> Float -> Float -> [Float]
for n min max =
  take n [min, min + delta ..]
  where
    delta = (max - min) / fromIntegral (n - 1)

sample :: Grid Point -> Image color -> Grid color
sample points image =
  map (map image) points

draw ::
  Grid Point ->
  (Point -> [Point]) ->
  [color] ->
  (Grid color -> image) ->
  image
draw points fractal palette render =
  render (sample points (fracImage fractal palette))

charPalette :: [Char]
charPalette = "    ,.‘\"~:;o-!|?/<>X+={^O#%&@8*$"

-- TODO: make interesting/nicer palettes!
-- (that's where most of the magic come from anyway)
rgbPalette :: [P.PixelRGBA8]
rgbPalette =
  map
    (\x -> P.PixelRGBA8 x x x 255)
    (map round (for 25 0.0 255.0))

charRender :: Grid Char -> IO ()
charRender = putStr . unlines

rgbRender :: FilePath -> Grid P.PixelRGBA8 -> IO ()
rgbRender filename g = do
  mImg <-
    createMutableImage
      (length (head g))
      (length g)
      (P.PixelRGBA8 0 0 0 255)
  _ <- sequence [writePixel mImg x y c | (row, y) <- zip g [0 ..], (c, x) <- zip row [0 ..]]
  finalImage <- unsafeFreezeImage mImg
  P.savePngImage filename (P.ImageRGBA8 finalImage)

{---------------------------------------------------------------------------
  Let's make some fractal ASCII art!

  To produce the images, evaluate the following IO actions in the REPL...
----------------------------------------------------------------------------}

asciiArt1 =
  draw points mandelbrot charPalette charRender
  where
    points = grid 79 37 (-2.25, -1.5) (0.75, 1.5)

asciiArt2 =
  draw points mandelbrot charPalette charRender
  where
    points = grid 79 37 (-1.15, 0.19) (-0.75, 0.39)

asciiArt3 =
  draw points (julia (0.3, 0.0043)) charPalette charRender
  where
    points = grid 79 37 (-1.5, -1.5) (1.5, 1.5)

{---------------------------------------------------------------------------
  Let's render some actual images to disk!

  To produce the images, evaluate the following IO actions (feel free
  to change filename and parameters).
----------------------------------------------------------------------------}

fullMandelbrot =
  draw points mandelbrot rgbPalette (rgbRender "full-mandelbrot.png")
  where
    points = grid' 500 500 (-0.5, 0) 2.5

linkedinBanner_5 =
  draw points mandelbrot rgbPalette (rgbRender "linkedin-banner.png")
  where
    points = grid' 1584 396 (-0.768578, 0.2547592) 0.16

nicePic =
  draw points mandelbrot rgbPalette (rgbRender "nicePic.png")
  where
    points = grid' 500 396 (-0.768578, 0.2547592) 0.16
