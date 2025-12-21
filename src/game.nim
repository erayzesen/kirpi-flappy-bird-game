import kirpi
import math, std/random

#region Game Properties
# Basic physics and spacing constants for game balance
let gravity:float= 1200
let speed:float = 200
let pipeSpacing:float = 400
let minPipeGap:float = 150
let maxPipeGap:float = 100
#endregion

#region Helper Variables
type 
  State = enum 
    MainMenu,Tutorial,GamePlay,GameOver
var gameState=State.MainMenu
let baseGameWidth:float = 800.0
let baseGameHeight:float = 600.0
var isGameOver = false
var score = 0
var highScore = 0
var shockRectAlpha:int =0 # For flash effect on hit
var fadeRectAlpha:int =255 # For screen transition fade
#endregion

#region Helper Procs
# Standard AABB (Axis-Aligned Bounding Box) collision detection
proc isColliding(rect1:tuple[x:float,y:float,w:float,h:float],rect2:tuple[x:float,y:float,w:float,h:float] ) :bool =
  if rect1.x < rect2.x + rect2.w and
     rect1.x + rect1.w > rect2.x and
     rect1.y < rect2.y + rect2.h and
     rect1.y + rect1.h > rect2.y :
    return true
  return false
#endregion

#region Bird
type 
  Bird = object
    x: float
    y: float
    vy: float # Vertical velocity
    rotation: float

var bird: Bird
var birdTexture: Texture
#endregion

#region Pipes 
type 
  Pipe = object
    x:float 
    y: float
    gap: float
    scored : bool=false

var pipeUpTexture: Texture
var pipeDownTexture: Texture
var pipes: seq[Pipe] = @[]
var lastPipeIndex: int = -1

# Respawns a pipe at the end of the line with randomized height and gap
proc reSpawnPipe(pipeIndex:int) =
  pipes[pipeIndex].scored = false
  pipes[pipeIndex].gap=minPipeGap+rand(maxPipeGap).float
  let heightRange:float=window.getHeight().float*0.3
  pipes[pipeIndex].y=heightRange+rand(heightRange.int).float
  pipes[pipeIndex].x=pipes[lastPipeIndex].x+pipeSpacing
  lastPipeIndex=pipeIndex
#endregion

#region Parallax Backgrounds
type 
  ParallaxLayer = object
    x: float
    y: float

var groundTexture: Texture
var backgroundTexture: Texture
var groundLayers : seq[ParallaxLayer] = @[]
var lastGroundIndex: int = -1
var backgroundLayers : seq[ParallaxLayer] = @[]
var lastBackgroundIndex: int = -1
#endRegion

#region UI
var logoTexture: Texture
var startInfoTexture: Texture
var tutorialTexture: Texture
var getReadyTexture: Texture
var gameOverTexture: Texture

proc drawMainMenu() =
  # Centering the logo and start instructions
  draw(logoTexture, (window.getWidth().float - logoTexture.width.float) * 0.5, window.getHeight().float * 0.2)
  draw(startInfoTexture, (window.getWidth().float - startInfoTexture.width.float) * 0.5, window.getHeight().float * 0.5)

proc drawTutorialPhase() =
  # Displayed before the first flap
  draw(getReadyTexture, (window.getWidth().float - getReadyTexture.width.float) * 0.5, window.getHeight().float * 0.2)
  draw(tutorialTexture, (window.getWidth().float - tutorialTexture.width.float) * 0.5+50, window.getHeight().float * 0.5-birdTexture.height.float*0.5)

proc drawGameOver() =
  draw(gameOverTexture, (window.getWidth().float - gameOverTexture.width.float) * 0.5, window.getHeight().float * 0.2)
  push() # Save coordinate state
  pushState() # Save current style state (color, etc.)
  
  let panelWidth:float =300
  let panelHeight:float =165
  let panelRadius: float =20
  
  translate((window.getWidth().float - panelWidth)*0.5,(window.getHeight().float-panelHeight)*0.5)
  
  # Draw background panel for scores
  setColor("#fcffb5")
  rectangle(DrawModes.Fill, 0, 0, panelWidth, panelHeight,panelRadius)
  setColor("#472022")
  setLine(8.0)
  rectangle(DrawModes.Line, 0, 0, panelWidth, panelHeight,panelRadius)
  
  var ry: float = 30
  let fontSize: float= 36.0
  
  # Render current score
  let scoreText = newText("Score: " & $score, getDefaultFont())
  let scoreTextSize= scoreText.getSizeWith(fontSize)
  draw( scoreText, panelWidth*0.5-scoreTextSize.x*0.5, ry, fontSize )
  
  ry += scoreTextSize.y + 20
  
  # Render high score
  let hScoreText = newText("High Score: " & $highScore, getDefaultFont())
  let hScoreTextSize= hScoreText.getSizeWith(fontSize)
  draw( hScoreText, panelWidth*0.5-hScoreTextSize.x*0.5, ry, fontSize )
  
  popState() # Restore style state
  draw(startInfoTexture, (panelWidth-startInfoTexture.width.float) * 0.5, panelHeight+50.0)
  pop() # Restore coordinate state

#endregion

#region Sounds 

var flapSound = newSound("src/resources/sounds/flap.mp3",SoundType.Static)
var scoreSound = newSound("src/resources/sounds/score.mp3",SoundType.Static)
var hitSound = newSound("src/resources/sounds/hit.mp3",SoundType.Static)
var dieSound = newSound("src/resources/sounds/die.mp3",SoundType.Static)
#endregion

#region Game
proc changeState(newState:State) =
  # Trigger fade out effect when returning to menu or starting over
  if gameState == State.GameOver or gameState == State.MainMenu :
    fadeRectAlpha = 255
  gameState = newState
  

proc restartGame() =
  # Reset game session variables
  score = 0
  bird = Bird(x:window.getWidth().float*0.3,y:window.getHeight().float*0.5)
  
  # Reset and pool pipes
  pipes.setLen(0)
  let pipeCount = 4
  for i in 0..pipeCount-1 :
    let gap:float=minPipeGap+rand(maxPipeGap).float
    let heightRange:float=window.getHeight().float*0.3
    let posY:float=heightRange+rand(heightRange.int).float
    let posX:float =window.getWidth().float*1.5+pipeSpacing*i.float
    pipes.add(Pipe(x:posX, y:posY, gap:gap))
  lastPipeIndex = pipeCount - 1

  # Reset infinite ground layers
  groundLayers.setLen(0)
  let groundCount = 4
  for i in 0..groundCount-1 :
    groundLayers.add(ParallaxLayer(x:groundTexture.width*i.float, y:window.getHeight().float - groundTexture.height.float*0.80))
  lastGroundIndex = groundCount - 1

  # Reset infinite background layers
  backgroundLayers.setLen(0)
  let backgroundCount = 2
  for i in 0..backgroundCount-1 :
    backgroundLayers.add(ParallaxLayer(x:backgroundTexture.width*i.float, y:0))
  lastBackgroundIndex = backgroundCount - 1
    

proc load() =
  # Resource loading
  
  logoTexture = newTexture("src/resources/game_logo.png")
  startInfoTexture= newTexture("src/resources/start_info.png")
  tutorialTexture= newTexture("src/resources/tutorial.png")
  getReadyTexture= newTexture("src/resources/get_ready.png")
  gameOverTexture= newTexture("src/resources/game_over.png")
  
  groundTexture = newTexture("src/resources/ground.png")
  backgroundTexture = newTexture("src/resources/background.png")
  
  birdTexture = newTexture("src/resources/bird.png")
  pipeUpTexture = newTexture("src/resources/pipe_up.png")
  pipeDownTexture = newTexture("src/resources/pipe_down.png")
  
  restartGame()
  discard
  

proc update( dt:float) =
  # Handle screen effects timers
  if fadeRectAlpha > 0 :
    fadeRectAlpha -= (10*dt).int
  if shockRectAlpha > 0 :
    shockRectAlpha -= (10*dt).int
  
  # Bird Physics (Gravity and Movement)
  if gameState == State.GamePlay or gameState == State.GameOver :
    bird.x=window.getWidth().float*0.3
    bird.vy += gravity * dt
    bird.y+=bird.vy * dt
    # Rotate the bird based on its vertical velocity over time
    bird.rotation=clamp(bird.rotation+2*dt,-PI*0.5,PI*0.5)

    # Collision with Ground
    if bird.y+birdTexture.height*0.5 > window.getHeight().float - groundTexture.height.float*0.8 :
      bird.y = window.getHeight().float - groundTexture.height.float*0.8 - birdTexture.height*0.5
      bird.vy = 0
      bird.rotation=PI*0.5
      if gameState != State.GameOver :
        echo "Game Over! Final Score: ", score
        hitSound.play()
        shockRectAlpha=255
        changeState(State.GameOver)

  # Input handling for different game states
  if gameState == State.GameOver: 
    if isMouseButtonPressed(MouseButton.Left) :
      restartGame()
      changeState(State.Tutorial)
    return

  if gameState == State.MainMenu :
    if isMouseButtonPressed(MouseButton.Left) :
      changeState(State.Tutorial)
  elif gameState == State.Tutorial :
    if isMouseButtonPressed(MouseButton.Left) :
      changeState(State.GamePlay)
  
  # Gameplay Logic
  if gameState == State.GamePlay :
    if isMouseButtonPressed(MouseButton.Left) :
      bird.vy = -gravity * 0.4
      bird.rotation= -PI*0.3
      flapSound.play()

    # Update Pipes and check for score
    for i in 0..<pipes.len :
      pipes[i].x -= speed * dt
      
      # Scoring logic: if bird passes pipe center
      if not pipes[i].scored and pipes[i].x + pipeUpTexture.width*0.5 < bird.x :
        pipes[i].scored = true
        score += 1
        scoreSound.play()
        if score > highScore :
          highScore = score
          
      # Respawn logic: if pipe goes off-screen
      if pipes[i].x < -pipeUpTexture.width.float*0.5 :
        reSpawnPipe(i)

    # Collision Logic: Bird vs Pipes
    var birdRect=(x:bird.x-birdTexture.width*0.5,y:bird.y-birdTexture.height*0.5,w:birdTexture.width.float,h:birdTexture.height.float)
    for i in 0..<pipes.len :
      var pipeUpRect=(x:pipes[i].x - pipeUpTexture.width*0.5,
                      y:pipes[i].y - (pipes[i].gap*0.5 + pipeUpTexture.height ),
                      w:pipeUpTexture.width.float,
                      h:pipeUpTexture.height.float)
      var pipeDownRect=(x:pipes[i].x - pipeDownTexture.width*0.5,
                        y:pipes[i].y + pipes[i].gap*0.5,
                        w:pipeDownTexture.width.float,
                        h:pipeDownTexture.height.float)

      if birdRect.isColliding(pipeUpRect) or birdRect.isColliding(pipeDownRect) :
        echo "Game Over! Final Score: ", score
        shockRectAlpha=255
        hitSound.play()
        dieSound.play()
        changeState(State.GameOver)

  # Infinite Scrolling logic for Grounds and Backgrounds
  # Ground Movement
  for i in 0..<groundLayers.len :
    groundLayers[i].x -= speed * dt

  for i in 0..<groundLayers.len :
    if groundLayers[i].x < -groundTexture.width.float :
      groundLayers[i].x = groundLayers[lastGroundIndex].x + groundTexture.width.float
      lastGroundIndex = i
      
  # Background Movement (Slower for Parallax effect)
  for i in 0..<backgroundLayers.len :
    backgroundLayers[i].x -= (speed*0.5) * dt
  
  for i in 0..<backgroundLayers.len :
    if backgroundLayers[i].x < -backgroundTexture.width.float :
      backgroundLayers[i].x = backgroundLayers[lastBackgroundIndex].x + backgroundTexture.width.float
      lastBackgroundIndex = i
  
proc config(appSettings:var AppSettings) =
  appSettings.window.resizeable=false
  appSettings.window.width=800
  appSettings.window.height=600
  appSettings.printFPS=true

proc draw() =
  clear("#00adae")
  
  # Rendering Background (Parallax)
  for i in 0..<backgroundLayers.len :
    push()
    translate(backgroundLayers[i].x,backgroundLayers[i].y)
    draw(backgroundTexture,0, 0 )
    pop()

  # Rendering Pipes
  for i in 0..<pipes.len :
    push()
    translate(pipes[i].x,pipes[i].y)
    draw(pipeUpTexture,-pipeUpTexture.width*0.5, -(pipeUpTexture.height+pipes[i].gap*0.5) )
    draw(pipeDownTexture,-pipeDownTexture.width*0.5, pipes[i].gap*0.5 )
    pop()

  # Rendering Ground
  for i in 0..<groundLayers.len :
    push()
    translate(groundLayers[i].x,groundLayers[i].y)
    draw(groundTexture,0, 0 )
    pop()

  # UI Overlays for Menu and Tutorial
  if gameState == State.MainMenu :
    drawMainMenu()
    return

  if gameState == State.Tutorial :
    drawTutorialPhase()
    
  # Rendering Bird with its rotation
  push()
  translate(bird.x , bird.y)
  rotate(bird.rotation)
  draw(birdTexture, -birdTexture.width*0.5 , -birdTexture.height*0.5)
  pop()

  # In-game score display
  if gameState == State.GamePlay :
    let fontSize = 32.0
    var scoreText= newText($score, getDefaultFont())
    var scoreTextSize= scoreText.getSizeWith(fontSize)
    var rectColor=Color("#fcffb5")
    rectColor.a=200.uint8
    setColor(rectColor)
    rectangle(DrawModes.Fill,(window.getWidth().float - scoreTextSize.x)*0.5-20,25,scoreTextSize.x+40,scoreTextSize.y+20,20)
    setColor("#472022")
    draw( scoreText, (window.getWidth().float - scoreTextSize.x)*0.5,35,fontSize)
    setColor(White)

  if gameState == State.GameOver :
    drawGameOver()

  # Drawing Flash/Shock Effect
  if shockRectAlpha > 0 :
    var shockColor=White
    shockColor.a=shockRectAlpha.uint8
    setColor( shockColor)
    rectangle(DrawModes.Fill,0, 0, window.getWidth().float, window.getHeight().float)
    shockRectAlpha -= 10
    setColor(White)

  # Drawing Scene Transition Fade
  if fadeRectAlpha > 0 :
    var fadeColor=Color("#472022")
    fadeColor.a=fadeRectAlpha.uint8
    setColor( fadeColor)
    rectangle(DrawModes.Fill,0, 0, window.getWidth().float, window.getHeight().float)
    fadeRectAlpha -= 10
    setColor(White)
  

run("Flappy Bird with Kirpi",load,update,draw,config)
#endregion