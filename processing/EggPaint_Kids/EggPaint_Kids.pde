/*
  EggPaint Kids Edition
 
 Real-time painting software for EggBot
 
 https://github.com/spaelectronics/eggpaint-kids
 
 Requires: 
 
 TODO: 
 
 */

import de.looksgood.ani.*;
import processing.serial.*;
import javax.swing.UIManager;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import javax.swing.ImageIcon;
import javax.swing.JSlider;
import javax.swing.JComboBox;


// User Settings: 
float MotorSpeed = 400.0;   // Steps per second, 1500 default
int ServoSpeed = 50;        // Brush UP/DN Speed. Values between 0 - 255 (Lower is slower).

int ServoUpPct = 55;        // Brush UP position, %  (higher number lifts higher). 
int ServoPaintPct = 100;    // Brush DOWN position, %  (higher number lifts higher).  

int centerPosition = 87;    // Arm Center Position

boolean reverseMotorX = false;
boolean reverseMotorY = false;

int delayAfterRaisingBrush = 400;  //ms
int delayAfterLoweringBrush = 400; //ms

int brushSize = 4;            // Brush Stroke Size
int ColorFadeDist = 1000;     // How slowly paint "fades" when drawing (higher number->Slower fading)
int ColorFadeStart = 100000;  // How far you can paint before paint "fades" when drawing

int minDist = 1;              // Minimum drag distance to record

boolean debugMode = false;


// Offscreen buffer images for holding drawn elements, makes redrawing MUCH faster
PGraphics offScreen;

PImage imgBackground;   // Stores background data image only.
PImage imgMain;         // Primary drawing canvas
PImage imgLocator;      // Cursor crosshairs
PImage imgButtons;      // Text buttons
PImage imgHighlight;
String BackgroundImageName = "background.png";
String HelpImageName = "help.png";

float ColorDistance;
boolean segmentQueued = false;
int queuePt1 = -1;
int queuePt2 = -1;

//float MotorStepsPerPixel =  16.75;  // For use with 1/16 steps
float MotorStepsPerPixel = 4.57;      // Good for 1/8 steps-- standard behavior.
int xMotorPaperOffset =  0;           // 1400 For 1/8 steps  Use 2900 for 1/16?

// Positions of screen items

float paintSwatchX = 43.8;
float paintSwatchY0 = 84.5;
float paintSwatchyD = 54.55;
int paintSwatchOvalWidth = 64;
int paintSwatchOvalheight = 47;

int MousePaperLeft =  121;
int MousePaperRight =  830;
int MousePaperTop =  120;
int MousePaperBottom =  300;

int xMotorOffsetPixels = 0;  // Corrections to initial motor position w.r.t. lower plate (paints & paper)
int yMotorOffsetPixels = 0;


int xBrushRestPositionPixels = 0;     // Brush rest position, in pixels
int yBrushRestPositionPixels = MousePaperTop + yMotorOffsetPixels;

int ServoUp;       // Brush UP position, native units
int ServoPaint;    // Brush DOWN position, native units. 

int MotorMinX;
int MotorMinY;
int MotorMaxX;
int MotorMaxY;

color[] paintset = new color[9]; 

color Brown =  color(139, 69, 19);   // BROWN
color Purple = color(148, 0, 211);   // PURPLE
color Blue = color(0, 0, 255);       // BLUE
color Green = color(0, 128, 0);      // GREEN
color Yellow = color(255, 255, 0);   // YELLOW
color Orange = color(255, 140, 0);   // ORANGE
color Red = color(255, 0, 0);        // RED
color Black = color(25, 25, 25);     // BLACK
color Water = color(230, 230, 255);  // No Color Selected 

boolean doSerialConnect = true;
boolean SerialOnline;
Serial myPort;       // Create object from Serial class
int val;             // Data received from the serial port

boolean BrushDown;
boolean BrushDownAtPause;
boolean DrawingPath = false;

int xLocAtPause;
int yLocAtPause;

int MotorX;         // Position of X motor
int MotorY;         // Position of Y motor
int MotorLocatorX;  // Position of X motor locator
int MotorLocatorY;  // Position of Y motor locator
int lastPosition;   // Record last encoded position for drawing

int selectedColor;
int highlightedColor; 

int brushColor;

boolean recordingGesture;
boolean forceRedraw;
boolean shiftKeyDown;
boolean keyup = false;
boolean keyright = false;
boolean keyleft = false;
boolean keydown = false;
boolean hKeyDown = false;
int lastButtonUpdateX = 0;
int lastButtonUpdateY = 0;


color color_for_new_ToDo_paths = Water;
boolean lastBrushDown_DrawingPath;
int lastX_DrawingPath;
int lastY_DrawingPath;


int NextMoveTime;               // Time we are allowed to begin the next movement (i.e., when the current move will be complete).
int SubsequentWaitTime = -1;    // How long the following movement will take.
int UIMessageExpire;
int raiseBrushStatus;
int lowerBrushStatus;
int moveStatus;
int MoveDestX;
int MoveDestY;
int PaintDest;
int getPaintStatus;
boolean Paused;


int ToDoList[];  // Queue future events in an integer array; executed when PriorityList is empty.
int indexDone;    // Index in to-do list of last action performed
int indexDrawn;   // Index in to-do list of last to-do element drawn to screen
boolean replayIsRunning;
boolean clearIsRunning;


// Active buttons
PFont font_ML16;
PFont font_CB; // Command button font
PFont font_url;


int TextColor = 75;
int LabelColor = 150;
color TextHighLight = Black;
int DefocusColor = 175;

SimpleButton pauseButton;
SimpleButton brushUpButton;
SimpleButton brushDownButton;
SimpleButton homeButton;
SimpleButton motorOffButton;
SimpleButton motorZeroButton;
SimpleButton clearButton;
SimpleButton printButton;
SimpleButton urlButton;
SimpleButton openButton;
SimpleButton saveButton;
SimpleButton settingsButton;

SimpleButton brushLabel;
SimpleButton motorLabel;
SimpleButton UIMessage;

void setup() 
{
  size(864, 519);
  
  PImage icon = loadImage("icon.png");
  surface.setIcon(icon);

  Ani.init(this); // Initialize animation library
  Ani.setDefaultEasing(Ani.LINEAR);

  offScreen = createGraphics(864, 519, JAVA2D);
  
  //// Allow frame to be resized?
  //  if (frame != null) {
  //    frame.setResizable(true);
  //  }

  surface.setTitle("EggPaint Kids Edition!");

  shiftKeyDown = false;

  frameRate(60);  // sets maximum speed only


  paintset[0] = Black;
  paintset[1] = Red;
  paintset[2] = Orange;
  paintset[3] = Yellow;
  paintset[4] = Green;
  paintset[5] = Blue;
  paintset[6] = Purple;
  paintset[7] = Brown;
  paintset[8] = Water;

  MotorMinX = 0;
  MotorMinY = 0;
  MotorMaxX = int(floor(xMotorPaperOffset + float(MousePaperRight - MousePaperLeft) * MotorStepsPerPixel));
  MotorMaxY = int(floor(float(MousePaperBottom - MousePaperTop) * MotorStepsPerPixel));

  lastPosition = -1;

  //if (debugMode) {
  //  println("MotorMinX: " + MotorMinX + "  MotorMinY: " + MotorMinY);
  //  println("MotorMaxX: " + MotorMaxX + "  MotorMaxY: " + MotorMaxY);
  //}


  ServoUp = 7500 + 175 * ServoUpPct;        // Brush UP position, native units
  ServoPaint = 7500 + 175 * ServoPaintPct;  // Brush DOWN position, native units.




  // Button setup
  font_ML16  = loadFont("Miso-Light-16.vlw");
  font_CB = loadFont("Miso-20.vlw");
  font_url = loadFont("Zar-casual-16.vlw"); 


  int xbutton = MousePaperLeft;
  int ybutton = MousePaperBottom + 25;

  pauseButton = new SimpleButton("RealTime: Off", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 120;

  brushLabel = new SimpleButton("Brush:", xbutton, ybutton, font_CB, 20, LabelColor, LabelColor);
  xbutton += 45;
  brushUpButton = new SimpleButton("Up", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 22;
  brushDownButton = new SimpleButton("Down", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 44;
  homeButton = new SimpleButton("Home", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 60;

  motorLabel = new SimpleButton("Motors:", xbutton, ybutton, font_CB, 20, LabelColor, LabelColor);
  xbutton += 55;
  motorOffButton = new SimpleButton("Off", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 30;
  motorZeroButton = new SimpleButton("Zero", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 70;
  clearButton = new SimpleButton("Clear All", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 80;
  printButton = new SimpleButton("Print Egg", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);

  xbutton = MousePaperLeft - 30;
  ybutton =  30;

  openButton = new SimpleButton("Open File", xbutton, ybutton, font_url, 16, LabelColor, TextHighLight); 
  xbutton += 80;
  saveButton = new SimpleButton("Save File", xbutton, ybutton, font_url, 16, LabelColor, TextHighLight);

  xbutton = 730;

  urlButton = new SimpleButton("Get a EggBot!", xbutton, ybutton, font_url, 16, LabelColor, TextHighLight);

  UIMessage = new SimpleButton("Welcome to EggPaint Kids! Hold 'h' key for help!", MousePaperLeft, MousePaperTop - 10, font_CB, 20, LabelColor, LabelColor);
  
  settingsButton = new SimpleButton("Settings", MousePaperRight - 50, MousePaperTop - 10, font_CB, 20, LabelColor, LabelColor);




  UIMessage.label = "Searching For EggBot... ";
  UIMessageExpire = millis() + 25000;

  rectMode(CORNERS);


  MotorX = 0;
  MotorY = 0;

  ToDoList = new int[0];
  ToDoList = append(ToDoList, -35);  // Command code: Go home (0,0)

  indexDone = -1;    // Index in to-do list of last action performed
  indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

  highlightedColor = 8;
  selectedColor = 8; // No color selected, to begin with
  brushColor = 8; // No paint on brush yet.  Use value 8, "water"
  ColorDistance = 0;


  raiseBrushStatus = -1;
  lowerBrushStatus = -1;
  moveStatus = -1;
  MoveDestX = -1;
  MoveDestY = -1;

  PaintDest = -1;
  getPaintStatus = -1; 

  Paused = true;
  BrushDownAtPause = false;
  replayIsRunning = false;
  clearIsRunning = false;

  // Set initial position of indicator at carriage minimum 0,0
  int[] pos = getMotorPixelPos();

  background(255);
  MotorLocatorX = pos[0];
  MotorLocatorY = pos[1];

  NextMoveTime = millis();
  imgBackground = loadImage(BackgroundImageName);  // Load the image into the program  
  drawToDoList();
  redrawButtons();
  redrawHighlight();
  redrawLocator();
}


void pause()
{
  pauseButton.displayColor = TextColor;
  if (Paused)
  {
    Paused = false;
    pauseButton.label = "RealTime: On";


    if (BrushDownAtPause)
    {
      int waitTime = NextMoveTime - millis();
      if (waitTime > 0)
      {
        delay (waitTime);  // Wait for prior move to finish:
      }

      if (BrushDown) {
        raiseBrush();
      }

      waitTime = NextMoveTime - millis();
      if (waitTime > 0)
      {
        delay (waitTime);  // Wait for prior move to finish:
      }

      MoveToXY(xLocAtPause, yLocAtPause);

      waitTime = NextMoveTime - millis();
      if (waitTime > 0)
      {
        delay (waitTime);  // Wait for prior move to finish:
      }

      lowerBrush();
    }
  }
  else
  {
    Paused = true;
    pauseButton.label = "RealTime: Off";
    //TextColor


    if (BrushDown) {
      BrushDownAtPause = true;
      raiseBrush();
    }
    else
      BrushDownAtPause = false;

    xLocAtPause = MotorX;
    yLocAtPause = MotorY;
  }

  redrawButtons();
}

boolean serviceBrush()
{
  // Manage processes of getting paint, water, and cleaning the brush,
  // as well as general lifts and moves.  Ensure that we allow time for the
  // brush to move, and wait respectfully, without local wait loops, to
  // ensure good performance for the artist.

  // Returns true if servicing is still taking place, and false if idle.

  boolean serviceStatus = false;

  int waitTime = NextMoveTime - millis();
  if (waitTime >= 0)
  {
    serviceStatus = true;
    // We still need to wait for *something* to finish!
  }
  else {
    if (raiseBrushStatus >= 0)
    {
      raiseBrush();
      serviceStatus = true;
    }
    else if (lowerBrushStatus >= 0)
    {
      lowerBrush();
      serviceStatus = true;
    }
    else if (moveStatus >= 0) {
      MoveToXY(); // Perform next move, if one is pending.
      serviceStatus = true;
    }
  }
  return serviceStatus;
}


void drawToDoList()
{
  // Erase all painting on main image background, and draw the existing "ToDo" list
  // on the off-screen buffer.

  int j = ToDoList.length;
  int x1, x2, y1, y2;
  int intTemp = -100;

  color interA;
  float brightness;
  color white = color(255, 255, 255);

  if ((indexDrawn + 1) < j)
  {

    // Ready the offscreen buffer for drawing onto
    offScreen.beginDraw();

    if (indexDrawn < 0)
      offScreen.image(imgBackground, 0, 0);  // Copy original background image into place!
    else
      offScreen.image(imgMain, 0, 0);


    offScreen.strokeWeight(brushSize);
    offScreen.stroke(color_for_new_ToDo_paths);

    x1 = 0;
    y1 = 0;

    while ( (indexDrawn + 1) < j) {

      indexDrawn++;
      // NOTE:  We increment the "Drawn" count here at the beginning of the loop,
      //        momentarily indicating (somewhat inaccurately) that the so-numbered
      //        list element has been drawn-- really, we're in the process of drawing it,
      //        and everything will be back to accurate once we're outside of the loop.


      intTemp = ToDoList[indexDrawn];

      if (intTemp >= 0)
      {  // Preview a path segment

        x2 = floor(intTemp / 10000);
        y2 = intTemp - 10000 * x2;

        if (DrawingPath)
          if ((x1 + y1) == 0)    // first time through the loop
          {
            intTemp = ToDoList[indexDrawn - 1];
            if (intTemp >= 0)
            {  // first point on this segment can be taken from history!

              x1 = floor(intTemp / 10000);
              y1 = intTemp - 10000 * x1;
            }
          }

        if (DrawingPath == false) {  // Just starting a new path
          DrawingPath = true;
          x1 = x2;
          y1 = y2;
        }

        if (color_for_new_ToDo_paths == Water)
          interA = Water;
        else {
          if (ColorDistance <  ColorFadeStart)
            brightness = 0.3;
          else if (ColorDistance < (ColorFadeStart + ColorFadeDist))
            brightness = 0.3 + 0.6 * ((ColorDistance - ColorFadeStart) /ColorFadeDist);
          else
            brightness = 0.9;

          interA = lerpColor(color_for_new_ToDo_paths, white, brightness);
        }

        offScreen.stroke(interA);
        offScreen.line(x1, y1, x2, y2);
        ColorDistance += getDistance(x1, y1, x2, y2); 

        x1 = x2;
        y1 = y2;
      }
      else
      {    // intTemp < 0, so we are doing something else.
        intTemp = -1 * intTemp;
        DrawingPath = false;

        if ((intTemp > 9) && (intTemp < 20))
        {  // Change paint color
          intTemp -= 10;
          color_for_new_ToDo_paths = paintset[intTemp];
          offScreen.stroke(paintset[intTemp]);
          //        ColorDistance = 0;
        }

        else if (intTemp == 40)
        {  // Clean brush
          offScreen.stroke(paintset[8]); // Water color!
        }
        else if (intTemp == 30)
        {
          lastBrushDown_DrawingPath = false;
        }
        else if (intTemp == 31)
        {  // Lower brush
          lastBrushDown_DrawingPath = true;
        }
      }
    }

    offScreen.endDraw();

    imgMain = offScreen.get(0, 0, offScreen.width, offScreen.height);
  }
}

void queueSegmentToDraw(int prevPoint, int newPoint)
{
  segmentQueued = true;
  queuePt1 = prevPoint;
  queuePt2 = newPoint;
}


void drawQueuedSegment()
{    // Draw new "done" segment, on the off-screen buffer.

  int x1, x2, y1, y2;
  color interA;
  float brightness;

  if (segmentQueued)
  {
    segmentQueued = false;

    offScreen.beginDraw();     // Ready the offscreen buffer for drawing
    offScreen.image(imgMain, 0, 0);
    offScreen.strokeWeight(brushSize);

    interA = paintset[brushColor];

    if (interA != Water) {
      brightness = 0.25;
      color white = color(255, 255, 255);
      interA = lerpColor(interA, white, brightness);
    }

    offScreen.stroke(interA);

    x1 = floor(queuePt1 / 10000);
    y1 = queuePt1 - 10000 * x1;

    x2 = floor(queuePt2 / 10000);
    y2 = queuePt2 - 10000 * x2;

    offScreen.line(x1, y1, x2, y2);

    offScreen.endDraw();

    imgMain = offScreen.get(0, 0, offScreen.width, offScreen.height);
  }
}



void draw() {

  if (debugMode)
  {
    surface.setTitle("EggPaint Kids Edition!      " + int(frameRate) + " fps");
  }

  drawToDoList();

  // NON-DRAWING LOOP CHECKS ==========================================

  if (doSerialConnect == false)
    checkServiceBrush();


  checkHighlights();

  if (UIMessage.label != "")
    if (millis() > UIMessageExpire) {

      UIMessage.displayColor = lerpColor(UIMessage.displayColor, color(242), .5);
      UIMessage.highlightColor = UIMessage.displayColor;

      if (millis() > (UIMessageExpire + 500)) {
        UIMessage.label = "";
        UIMessage.displayColor = LabelColor;
      }
      redrawButtons();
    }


  // ALL ACTUAL DRAWING ==========================================

  if  (hKeyDown)
  {  // Help display
    image(loadImage(HelpImageName), 0, 0);
  }
  else
  {

    image(imgMain, 0, 0, width, height);    // Draw Background image  (incl. paint paths)

    // Draw buttons image
    image(imgButtons, 0, 0);

    // Draw highlight image
    image(imgHighlight, 0, 0);

    // Draw locator crosshair at xy pos, less crosshair offset
    image(imgLocator, MotorLocatorX+MousePaperLeft-10, MotorLocatorY-10);
  }


  if (doSerialConnect)
  {
    // FIRST RUN ONLY:  Connect here

      doSerialConnect = false;
      
      
      
    // Load settings from file
      String file[] = loadStrings("settings.ini");
      if (file != null)
      {
        // Debugging Info
        //if (debugMode) println("\nThere are " + file.length + " entries in the file.\n");
        //if (debugMode) println("Brush Size: " + file[0] + "\nMotor Speed: " + file[1] + "\nServo Speed: " + file[2] + "\nServo UP Position: " + file[3] + "\nServo DOWN Position: " + file[4]);
        // Load the settings into the program.
        brushSize = int(file[0]);
        MotorSpeed = float(file[1]);
        ServoSpeed = int(file[2]);
        ServoUpPct = int(file[3]);
        ServoPaintPct = int(file[4]);
        // Convert to native units
        ServoUp = 7500 + 175 * ServoUpPct;    // Brush UP position, native units.
        ServoPaint = 7500 + 175 * ServoPaintPct;   // Brush DOWN position, native units.
      }
      else
      {
        //if (debugMode) println("\nsettings.ini file does not exist! Using default settings.");
      }
      

    scanSerial();

    if (SerialOnline)
    {
      myPort.write("EM,1\r");  //Configure both steppers to 1/8 step mode

        // Configure brush lift servo endpoints and speed
      myPort.write("SC,4," + str(ServoPaint) + "\r");   // Brush DOWN position, for painting.
      myPort.write("SC,5," + str(ServoUp) + "\r");      // Brush UP position.
      myPort.write("SC,10," + str(ServoSpeed) + "\r");  // Set brush raising and lowering speed.
      //myPort.write("HM\r");                             // Home the EggBot.


      // Ensure that we actually raise the brush:
      BrushDown = true;
      raiseBrush();

      UIMessage.label = "Welcome to EggPaint Kids!  Hold 'h' key for help!";
      UIMessageExpire = millis() + 5000;
      //if (debugMode) println("Now entering interactive painting mode.\n");
      redrawButtons();
    }
    else
    {
      //if (debugMode) println("Now entering offline simulation mode.\n");

      UIMessage.label = "EggBot not found.  Entering Simulation Mode. ";
      UIMessageExpire = millis() + 5000;
      redrawButtons();
    }
  }
}

// Only need to redraw if hovering or changing state
void redrawButtons() {


  offScreen.beginDraw();
  offScreen.background(0, 0);

  DrawButtons(offScreen);

  offScreen.endDraw();

  imgButtons = offScreen.get(0, 0, offScreen.width, offScreen.height);
}


// Only need to redraw if hovering or change select on specific items
void redrawHighlight() {
  offScreen.beginDraw();
  offScreen.background(0, 0);

  // Indicate Highlighted Color:
  if ((highlightedColor >= 0) && (highlightedColor < 8)) {
    // Indicate which color is highlighted
    offScreen.stroke(0, 0, 0, 50);
    offScreen.strokeWeight(8);
    offScreen.noFill();
    offScreen.ellipse(paintSwatchX, paintSwatchY0 + highlightedColor * paintSwatchyD, paintSwatchOvalWidth, paintSwatchOvalheight);
  }

  // Indicate Selected Color:
  if ((selectedColor >= 0)  && (selectedColor < 8)) {
    // Indicate which color is selected
    offScreen.stroke(0, 0, 0, 100);
    offScreen.strokeWeight(4);
    offScreen.noFill();
    offScreen.ellipse(paintSwatchX, paintSwatchY0 + selectedColor * paintSwatchyD, paintSwatchOvalWidth, paintSwatchOvalheight);
  }

  offScreen.endDraw();
  imgHighlight = offScreen.get(0, 0, offScreen.width, offScreen.height);
}


// Draw the locator crosshair to the offscreen buffer and fill imgLocator with it
// Only need to redraw this when it changes color
void redrawLocator() {
  offScreen.beginDraw();
  offScreen.background(0, 0);

  offScreen.stroke(0, 0, 0, 128);
  offScreen.strokeWeight(2);
  int x0 = 10;
  int y0 = 10;

  if (BrushDown)
    offScreen.fill(paintset[brushColor]);
  else
    offScreen.noFill();

  offScreen.ellipse(x0, y0, 10, 10);

  offScreen.line(x0 + 5, y0, x0 + 10, y0);
  offScreen.line(x0 - 5, y0, x0 - 10, y0);
  offScreen.line(x0, y0 + 5, x0, y0 + 10);
  offScreen.line(x0, y0 - 5, x0, y0 - 10);
  offScreen.endDraw();

  imgLocator = offScreen.get(0, 0, 25, 25);
}

void mousePressed() {
  int i;
  boolean doHighlightRedraw = false;

  //The mouse button was just pressed!  Let's see where the user clicked!

  if (highlightedColor >= 0)        // Check if we are over paint colors:
  {
    selectedColor = highlightedColor;
    i = -1 * (selectedColor + 10);
    ToDoList = append(ToDoList, i);
    doHighlightRedraw = true;

    color_for_new_ToDo_paths = paintset[selectedColor];

    ColorDistance = 0;
  }
  else  if ((mouseX >= MousePaperLeft) && (mouseX <= MousePaperRight) && (mouseY >= MousePaperTop) && (mouseY <= MousePaperBottom))
  {

      if (selectedColor == 8)
      { // Force the selection of a color.
        JOptionPane.showMessageDialog(null, "No color is selected! \nPlease choose a color first!", "No Color Selected!",
                                                JOptionPane.INFORMATION_MESSAGE, new ImageIcon(dataPath("brush_icon.png")));
      } else {

    // Begin recording gesture   // Over paper!
    recordingGesture = true;

    ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)  (Only has an effect if the brush is already down.)
    ToDoList = append(ToDoList, xyEncodeInt2());    // Command Code: Move to first (X,Y) point
    ToDoList = append(ToDoList, -31);              // Command Code:  -31 (lower brush)
    doHighlightRedraw = true;
    }
  }

  if (doHighlightRedraw) {
    redrawLocator();
    redrawHighlight();
  }


  if (pauseButton.isSelected())
    pause();
  else if (brushUpButton.isSelected())  
  {

    if (Paused)
      raiseBrush();
    else
      ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)
  }
  else if (brushDownButton.isSelected()) {

    if (Paused)
      lowerBrush();
    else
      ToDoList = append(ToDoList, -31);   // Command Code:  -31 (lower brush)
  }
  else if (urlButton.isSelected()) {
    link("http://www.spaelectronics.com");
  }
  else if (homeButton.isSelected())
  {

    if (!Paused) pause();

      if (BrushDown == true) raiseBrush();
      MotorsOff();
      JOptionPane.showMessageDialog(null, "Push the \"Pen Arm\" all the way to the left side.\nPress OK when ready.", "Home", 
                                                JOptionPane.INFORMATION_MESSAGE, new ImageIcon(dataPath("brush_icon.png")));
      MoveRelativeXY(0, 100);
      zero();
  }
  else if (motorOffButton.isSelected())
    MotorsOff();
  else if (motorZeroButton.isSelected())
    zero();
  else if (clearButton.isSelected())
  {  // ***** CLEAR ALL *****

    clearIsRunning = true;
  
    selectedColor = 8; // No color selected
    brushColor = 8; // No paint on brush yet.  Use value 8, "water"
   // color_for_new_ToDo_paths = Water; // Change Drawing Color

    ToDoList = new int[0];
    //    ToDoList = append(ToDoList, -1 * (brushColor + 10));

    ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)
    ToDoList = append(ToDoList, -35);  // Command code: Go home (0,0)

    indexDone = -1;    // Index in to-do list of last action performed
    indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

    drawToDoList();

    Paused = true;
    pause();
    redrawHighlight();
  }
  else if (printButton.isSelected())  
  {
    // Clear indexDone to "zero" (actually, -1, since even element 0 is not "done.")   & redraw to-do list.
    
    replayIsRunning = true;
    printButton.label = "Printing...";
    printButton.displayColor = color(200, 0, 0);
    printButton.highlightColor = color(200, 0, 0);
    redrawButtons();
    
    indexDone = -1;    // Index in to-do list of last action performed
    indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen
    
    drawToDoList();
  }
  else if (saveButton.isSelected())
  {
    // Save file with dialog #####
    selectOutput("Output .eeb file name:", "SavefileSelected");
  }
  else if (openButton.isSelected())
  {
    // Open file with dialog #####
    selectInput("Select a EggPaint (.eeb) file to open:", "fileSelected");  // Opens file chooser
  }
  else if (settingsButton.isSelected())
  {
    // Display User Settings
    String[] brushList = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"};
    JComboBox field1 = new JComboBox(brushList);
    field1.setSelectedIndex(brushSize-1);

    JSlider field2 = new JSlider(JSlider.HORIZONTAL, 0, 100, int(map(MotorSpeed,100,1000,0,100)));
    JSlider field3 = new JSlider(JSlider.HORIZONTAL, 0, 100, int(map(ServoSpeed,20,160,0,100)));
    JSlider field4 = new JSlider(JSlider.HORIZONTAL, 0, 100, ServoUpPct);
    JSlider field5 = new JSlider(JSlider.HORIZONTAL, 0, 100, ServoPaintPct);

    //Turn on labels at major tick marks.
    field2.setMajorTickSpacing(25);
    field2.setMinorTickSpacing(5);
    field2.setPaintTicks(true);
    field2.setPaintLabels(true);
    field3.setMajorTickSpacing(25);
    field3.setMinorTickSpacing(5);
    field3.setPaintTicks(true);
    field3.setPaintLabels(true);
    field4.setMajorTickSpacing(25);
    field4.setMinorTickSpacing(5);
    field4.setPaintTicks(true);
    field4.setPaintLabels(true);
    field5.setMajorTickSpacing(25);
    field5.setMinorTickSpacing(5);
    field5.setPaintTicks(true);
    field5.setPaintLabels(true);

    Object[] message = {
        "Brush Stroke Size:", field1,
        "Motor Speed:", field2,
        "Servo Speed:", field3,
        "Servo Up Position:", field4,
        "Servo Down Position:", field5,
    };
    
    Object[] options = {"OK", "Restore Defaults", "Cancel"};
    int option = JOptionPane.showOptionDialog(null, message, "EggPaint Settings", JOptionPane.YES_NO_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE, null, options, options[0]);
    if (option == JOptionPane.YES_OPTION)
    {

      // Set the new variables
      brushSize = (int)field1.getSelectedIndex() + 1;
      MotorSpeed = map(field2.getValue(),0,100,100,1000);
      ServoSpeed = int(map(field3.getValue(),0,100,20,160));
      ServoUpPct = field4.getValue();
      ServoPaintPct = field5.getValue();

      // Configure servo lift, endpoints and speed
      ServoUp = 7500 + 175 * ServoUpPct;    // Brush UP position, native units
      ServoPaint = 7500 + 175 * ServoPaintPct;   // Brush DOWN position, native units.
      myPort.write("SC,4," + str(ServoPaint) + "\r");   // Brush DOWN position, for painting.
      myPort.write("SC,5," + str(ServoUp) + "\r");      // Brush UP position.
      myPort.write("SC,10," + str(ServoSpeed) + "\r");  // Set brush raising and lowering speed.

      // Add all settings to an array
      String[] output=new String[0];
      output=append(output,str(brushSize));
      output=append(output,str(MotorSpeed));
      output=append(output,str(ServoSpeed));
      output=append(output,str(ServoUpPct));
      output=append(output,str(ServoPaintPct));
      // Save settings to file
      saveStrings("settings.ini",output);
      
    }
     else if (option == JOptionPane.NO_OPTION)
    { // Restore Default Settings
    
      //if (debugMode) println("Default Settings Restored");
      brushSize = 4;          // Brush Stroke Size
      MotorSpeed = 400.0;     // Steps per second, 1500 default
      ServoSpeed = 50;        // Brush UP/DN Speed. Values between 0 - 255 (Lower is slower).
      ServoUpPct = 55;        // Brush UP position, %  (higher number lifts higher).
      ServoPaintPct = 100;    // Brush DOWN position, %  (higher number lifts higher).
      
      // Add all settings to an array
      String[] output=new String[0];
      output=append(output,str(brushSize));
      output=append(output,str(MotorSpeed));
      output=append(output,str(ServoSpeed));
      output=append(output,str(ServoUpPct));
      output=append(output,str(ServoPaintPct));
      // Save settings to file
      saveStrings("settings.ini",output);
      
      // Configure servo lift, endpoints and speed
      ServoUp = 7500 + 175 * ServoUpPct;    // Brush UP position, native units
      ServoPaint = 7500 + 175 * ServoPaintPct;   // Brush DOWN position, native units.
      myPort.write("SC,4," + str(ServoPaint) + "\r");   // Brush DOWN position, for painting.
      myPort.write("SC,5," + str(ServoUp) + "\r");      // Brush UP position.
      myPort.write("SC,10," + str(ServoSpeed) + "\r");  // Set brush raising and lowering speed.

      JOptionPane.showMessageDialog(null, "Default settings have been restored.", "Default Settings", JOptionPane.INFORMATION_MESSAGE);
    }
  }
}




void SavefileSelected(File selection) {    // SAVE FILE
  if (selection == null) {
    // If a file was not selected
    //if (debugMode) println("No output file was selected...");

    UIMessage.label = "File not saved (reason: no file name chosen).";
    UIMessageExpire = millis() + 3000;
  }
  else {

    String[] FileOutput;
    String savePath = selection.getAbsolutePath();
    String[] p = splitTokens(savePath, ".");
    boolean fileOK = false;

    FileOutput = new String[0];

    if ( p[p.length - 1].equals("EEB"))
      fileOK = true;
    if ( p[p.length - 1].equals("eeb"))
      fileOK = true;
    if (fileOK == false)
      savePath = savePath + ".eeb";

    // If a file was selected, print path to folder
    //if (debugMode) println("Save file: " + savePath);

    int listLength = ToDoList.length;
    for ( int i = 0; i < listLength; ++i) {

      FileOutput = append(FileOutput, str(ToDoList[i]));
    }

    saveStrings(savePath, FileOutput);

    UIMessage.label = "File Saved!";
    UIMessageExpire = millis() + 3000;
  }
}



void fileSelected(File selection) {    // LOAD (OPEN) FILE
  if (selection == null) {
    //if (debugMode) println("Window was closed or the user hit cancel.");

    UIMessage.label = "File not loaded (reason: no file selected).";
    UIMessageExpire = millis() + 3000;
  }
  else {
    String loadPath = selection.getAbsolutePath();

    // If a file was selected, print path to file
    //if (debugMode) println("Loaded file: " + loadPath);

    String[] p = splitTokens(loadPath, ".");
    boolean fileOK = false;
    int todoNew;


    if (p[p.length - 1].equals("EEB"))
      fileOK = true;
    if ( p[p.length - 1].equals("eeb"))
      fileOK = true;

    //if (debugMode) println("File OK: " + fileOK);

    if (fileOK) {

      String lines[] = loadStrings(loadPath);


      Paused = false;
      pause();
      printButton.displayColor = color(200, 0, 0);


      // Clear indexDone to "zero" (actually, -1, since even element 0 is not "done.")   & redraw to-do list.

      ToDoList = new int[0];
      indexDone = -1;    // Index in to-do list of last action performed
      indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

      drawToDoList();

      //if (debugMode) println("there are " + lines.length + " lines");
      for (int i = 0 ; i < lines.length; i++) {
        todoNew = parseInt(lines[i]);
        //if (debugMode) println(str(todoNew));
        ToDoList = append(ToDoList, todoNew);
      }
    }
    else {
      // Can't load file
      UIMessage.label = "File not loaded (reason: wrong file type).";
      UIMessageExpire = millis() + 3000;
    }
  }
}



void mouseDragged() { 

  int i;
  int posOld, posNew;

  boolean addpoint = false;
  float distTemp = 0;

  if (recordingGesture)
  {
    posNew = xyEncodeInt2();

    i = ToDoList.length;

    if (i > 1)
    {
      posOld = ToDoList[i - 1];

      if (posOld != posNew) {  // Avoid adding duplicate points to ToDoList!

        addpoint = true;
        distTemp = getDistance(posOld, posNew) ;
        // Only add points that are some minimum distance away from each other.
        if (distTemp < minDist) {
          addpoint = false;
        }

        if (addpoint)
          ToDoList = append(ToDoList, posNew);  // Command code: XY coordinate pair
      }
    }
    else
    { // List length may be zero.
      ToDoList = append(ToDoList, posNew);  // Command code: XY coordinate pair
    }
  }
}


void mouseReleased() {
  if (recordingGesture)
  {
    recordingGesture = false;
    ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)
  }
}


void keyReleased()
{

  if (key == CODED) {

    if (keyCode == UP) keyup = false;
    if (keyCode == DOWN) keydown = false;
    if (keyCode == LEFT) keyleft = false;
    if (keyCode == RIGHT) keyright = false;

    if (keyCode == SHIFT) {

      shiftKeyDown = false;
    }
  }

  if ( key == 'h')  // display help
  {
    hKeyDown = false;
  }
}



void keyPressed()
{
  if (key == CODED) {

    // Arrow keys are used for nudging, with or without shift key.

    if (keyCode == UP)
    {
      keyup = true;
    }
    if (keyCode == DOWN)
    {
      keydown = true;
    }
    if (keyCode == LEFT) keyleft = true;
    if (keyCode == RIGHT) keyright = true;
    if (keyCode == SHIFT) shiftKeyDown = true;
  }
  else
  {

    if ( key == 'b')   // Toggle brush up or brush down with 'b' key
    {
      if (BrushDown)
        raiseBrush();
      else
        lowerBrush();
    }

    if ( key == 'z')  // Zero motor coordinates
      zero();

    if ( key == ' ')  //Space bar: Pause
      pause();

    if ( key == 'q')  // Move home (0,0)
    {
      raiseBrush();
      MoveToXY(0, 0);
    }


    if ( key == 'h')  // display help
    {
      hKeyDown = true;
    }


    if ( key == 't')  // Disable motors, to manually move carriage. 
      MotorsOff();

    if ( key == '1')
      MotorSpeed = 100;
    if ( key == '2')
      MotorSpeed = 250;
    if ( key == '3')
      MotorSpeed = 500;
    if ( key == '4')
      MotorSpeed = 750;
    if ( key == '5')
      MotorSpeed = 1000;
    if ( key == '6')
      MotorSpeed = 1250;
    if ( key == '7')
      MotorSpeed = 1500;
    if ( key == '8')
      MotorSpeed = 1750;
    if ( key == '9')
      MotorSpeed = 2000;
  }
}