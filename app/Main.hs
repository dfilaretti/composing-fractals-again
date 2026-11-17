module Main (main) where

import Codec.Picture qualified as P
import Codec.Picture.Types (createMutableImage, unsafeFreezeImage, writePixel)

type Point = (Float, Float)

main :: IO ()
main = putStrLn "Hello, Haskell!"

-- TODO: so this with complex numbers instead!
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

type Image color = Point -> color

fracImage :: (Point -> [Point]) -> [color] -> Image color
fracImage fractal palette =
  chooseColor palette . fractal

type Grid a = [[a]]

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

rgbPalette :: [P.PixelRGBA8]
rgbPalette =
  map
    (\x -> P.PixelRGBA8 x x x 255)
    (map round (for 50 0.0 255.0))

charRender :: Grid Char -> IO ()
charRender = putStr . unlines

rgbRender :: FilePath -> Grid P.PixelRGBA8 -> IO ()
rgbRender filename g = do
  mImg <-
    createMutableImage
      (length (head g))
      (length g)
      (P.PixelRGBA8 0 0 0 255)
  sequence [writePixel mImg x y c | (row, y) <- zip g [0 ..], (c, x) <- zip row [0 ..]]
  xoxo <- unsafeFreezeImage mImg
  P.savePngImage filename (P.ImageRGBA8 xoxo)

image1 =
  draw points mandelbrot charPalette charRender
  where
    points = grid 79 37 (-2.25, -1.5) (0.75, 1.5)

image2 =
  draw points mandelbrot charPalette charRender
  where
    points = grid 79 37 (-1.15, 0.19) (-0.75, 0.39)

figure3 =
  draw points (julia (0.3, 0.0043)) charPalette charRender
  where
    points = grid 79 37 (-1.5, -1.5) (1.5, 1.5)

figure3left =
  draw points mandelbrot rgbPalette (rgbRender "woofoooo111.png")
  where
    points = grid 2000 700 (-2.25, -1.5) (0.75, 1.5)
