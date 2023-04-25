--Start of Global Scope---------------------------------------------------------
print('AppEngine Version: ' .. Engine.getVersion())

-- Delay in ms between visualization steps for demonstration purpose only
local DELAY = 1200

-- Creating viewer
local viewer = View.create()

-- Setting up graphical overlay attributes
local decoration = View.ShapeDecoration.create():setLineColor(0, 255, 0):setLineWidth(2)

local charDeco = View.TextDecoration.create():setSize(40):setColor(0, 255, 0)

-- Creating classifier and select font
local fontClassifier = Image.OCR.Halcon.FontClassifier.create()
fontClassifier:setFont('INDUSTRIAL_0_9A_Z_NOREJ')

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  local img = Image.load('resources/CircleText.png')
  local sector =
    Shape.createSector(Point.create(130, 130), 73, 120, -math.pi * .6, math.pi)
  viewer:addImage(img)
  viewer:addShape(sector, decoration)
  viewer:present()
  Script.sleep(DELAY) -- for demonstration purpose only

  -- Warp sector.
  -- The text is written counter-clockwise,
  -- rotate the warped image to get correct orientation.
  local warped = Image.warpSector(img, sector)
  img = warped:rotate(math.pi)
  viewer:clear()
  viewer:addImage(img)
  viewer:present()
  Script.sleep(DELAY) -- for demonstration purpose only

  -- Application tailored (free) segmentation of image to find characters
  ---------------------------------------------------------------------------------

  -- Find convex hull of dark areas
  local smoothImg = img:gauss(5)
  viewer:addImage(smoothImg)
  viewer:present()
  Script.sleep(DELAY) -- for demonstration purpose only

  local darkPix = img:threshold(0, 98)
  darkPix = darkPix:findConnected(100)
  darkPix = Image.PixelRegion.getConvexHull(darkPix)
  viewer:addPixelRegion(darkPix)
  viewer:present()
  Script.sleep(DELAY)

  -- Find light areas including text
  viewer:addImage(smoothImg)
  viewer:present()
  Script.sleep(DELAY)
  local brightPix = smoothImg:threshold(148, 255)
  viewer:addPixelRegion(brightPix)
  viewer:present()
  Script.sleep(DELAY)

  -- Find intersection between dark and light areas, i.e. the light areas inside the dark areas
  viewer:clear()
  viewer:addImage(img)
  local brightChars = Image.PixelRegion.getIntersection(darkPix, brightPix)
  local charBlobs = Image.PixelRegion.findConnected(brightChars, 200, 10000)
  viewer:addPixelRegion(charBlobs)
  viewer:present()
  Script.sleep(DELAY) -- for demonstration purpose only

  -- Sorting pixelregions from left to right
  local filter = Image.PixelRegion.Filter.create()
  filter:sortBy('CENTROIDX')
  charBlobs = filter:apply(charBlobs, img)

  -- Classifying all found characters
  local invSmoothImg = smoothImg:invert() -- used for classification
  local characters, _, _ = fontClassifier:classifyCharacters(charBlobs, invSmoothImg, '^[A-Z]{3}[0-9]{2}$')

  -- Drawing bounding boxes around each found text region
  for i = 1, #charBlobs do
    local box = charBlobs[i]:getBoundingBox()
    viewer:addShape(box, decoration)
    -- Printing classified characters in image
    local CoG = box:getCenterOfGravity()
    charDeco:setPosition(CoG:getX() - 10, CoG:getY() + 60)
    viewer:addText(characters:sub(i, i), charDeco)
    viewer:present() -- can be put outside loop if not for demonstration
    Script.sleep(DELAY / 7) -- for demonstration purpose only
  end
  print('App finished.')
end

--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
