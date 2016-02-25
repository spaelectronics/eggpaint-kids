/**
 * RoboPaint RT - watercolorbot control functions
 */

void raiseBrush() 
{  
  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    raiseBrushStatus = 1; // Flag to raise brush when no longer busy.
  }
  else
  {
    if (BrushDown == true) {
      if (SerialOnline) {
        myPort.write("SP,0\r");
        BrushDown = false;
        NextMoveTime = millis() + delayAfterRaisingBrush;
      }
      //      if (debugMode) println("Raise Brush.");
    }
    raiseBrushStatus = -1; // Clear flag.
  }
}

void lowerBrush() 
{
  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    lowerBrushStatus = 1;  // Flag to lower brush when no longer busy.
    // delay (waitTime);  // Wait for prior move to finish:
  }
  else
  { 
    if  (BrushDown == false)
    {      
      if (SerialOnline) {
        myPort.write("SP,1\r");           // Lower Brush
        BrushDown = true;
        NextMoveTime = millis() + delayAfterLoweringBrush;
        lastPosition = -1;
      }
      //      if (debugMode) println("Lower Brush.");
    }
    lowerBrushStatus = -1; // Clear flag.
  }
}


void MoveRelativeXY(int xD, int yD)
{
  // Change carriage position by (xDelta, yDelta), with XY limit checking, time management, etc.

  int xTemp = MotorX + xD;
  int yTemp = MotorY + yD;

  MoveToXY(xTemp, yTemp);
}

void getPaint(int paintColor)
{
  PaintDest = paintColor;


  if (PaintDest == 8)
  {
    //cleanBrush();  // Changing color to "water" -- just clean the brush.
  }
  else if ((PaintDest >= 0) && (PaintDest <= 7))
  {
    getPaintStatus = 0;  // Begin getPaint process
    getPaint();
  }
  else 
    getPaintStatus = -1;
}


void MoveToXY(int xLoc, int yLoc)
{
  MoveDestX = xLoc;
  MoveDestY = yLoc;

  MoveToXY();
}

void MoveToXY()
{
  int traveltime_ms;

  // Absolute move in motor coordinates, with XY limit checking, time management, etc.
  // Use MoveToXY(int xLoc, int yLoc) to set destinations.

  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    moveStatus = 1;  // Flag this move as not yet completed.
  }
  else
  {
    if ((MoveDestX < 0) || (MoveDestY < 0))
    { 
      // Destination has not been set up correctly.
      // Re-initialize varaibles and prepare for next move.  
      MoveDestX = -1;
      MoveDestY = -1;
    }
    else {

      moveStatus = -1;
      if (MoveDestX > MotorMaxX) 
        MoveDestX = MotorMaxX; 
      else if (MoveDestX < MotorMinX) 
        MoveDestX = MotorMinX; 

      if (MoveDestY > MotorMaxY) 
        MoveDestY = MotorMaxY; 
      else if (MoveDestY < MotorMinY) 
        MoveDestY = MotorMinY; 

      int xD = MoveDestX - MotorX;
      int yD = MoveDestY - MotorY;

      if ((xD != 0) || (yD != 0))
      {   

        MotorX = MoveDestX;
        MotorY = MoveDestY;

        int MaxTravel = max(abs(xD), abs(yD)); 
        traveltime_ms = int(floor( float(1000 * MaxTravel)/MotorSpeed));


        NextMoveTime = millis() + traveltime_ms -   ceil(1000 / frameRate);
        // Important correction-- Start next segment sooner than you might expect,
        // because of the relatively low framerate that the program runs at.
      
        

        if (SerialOnline) {
          if (reverseMotorX)
            xD *= -1;
          if (reverseMotorY)
            yD *= -1; 

          myPort.write("SM," + str(traveltime_ms) + "," + str(yD) + "," + str(xD) + "\r");
          //General command "SM,<duration>,<penmotor steps>,<eggmotor steps><CR>"
        }

        // Calculate and animate position location cursor
        int[] pos = getMotorPixelPos();
        float sec = traveltime_ms/1000.0;

        Ani.to(this, sec, "MotorLocatorX", pos[0]);
        Ani.to(this, sec, "MotorLocatorY", pos[1]);

        //        if (debugMode) println("Motor X: " + MotorX + "  Motor Y: " + MotorY);
      }
    }
  }
  
  // Need 
  // SubsequentWaitTime
}
















void getPaint()
{
  int waitTime = NextMoveTime - millis();
  if (waitTime <= 0)
  { // If wait time is > 0, this section does not execute, and status is left unchanged.

    int paintColor = PaintDest;
    //if (debugMode) println("Change Color!  Color: " + paintColor);
    
    
    // Convert the selected color to a word to display on screen
    String paintColorStr = "None";
    switch(paintColor) {
      case 0: 
        paintColorStr = "Black";
        break;
      case 1: 
        paintColorStr = "Red";
        break;
      case 2: 
        paintColorStr = "Orange";
        break;
      case 3: 
        paintColorStr = "Yellow";
        break;
      case 4: 
        paintColorStr = "Green";
        break;
      case 5: 
        paintColorStr = "Blue";
        break;
      case 6: 
        paintColorStr = "Purple";
        break;
      case 7: 
        paintColorStr = "Brown";
        break;
}
    
    
    
    int yC = round(centerPosition * MotorStepsPerPixel); // Center the Pen

    if (getPaintStatus == 0) 
    {
      if (brushColor == paintColor) {
        // Do Nothing... The new color is the same as current color.
      } else {
        // Change Color
        getPaintStatus = 1;
      }
    }
    
    if (getPaintStatus == 1) {
      raiseBrush();
      getPaintStatus = 2;
    }
    if (getPaintStatus == 2) {
      MoveToXY(MotorX, yC);  // Center the Pen
      JOptionPane.showMessageDialog(null, "Please Insert a \"" + paintColorStr + "\" Marker into the Pen Holder. \nPress OK to continue coloring the egg.", "Change Color!", 
                                                JOptionPane.INFORMATION_MESSAGE, new ImageIcon(dataPath("brush_icon.png")));
    }
    
      brushColor = paintColor;
      redrawLocator();
      getPaintStatus = -1;  // Flag that we are done with this operation.
      PaintDest = -1;
  }
}


void MotorsOff()
{
  if (SerialOnline)
  {    
    myPort.write("EM,0,0\r");  //Disable both motors

    //    if (debugMode) println("Motors disabled.");
  }
}

void zero()
{
  // Mark current location as (0,0) in motor coordinates.  
  // Manually move the motor carriage to the left-rear (upper left) corner before executing this command.

  MotorX = 0;
  MotorY = 0;

  moveStatus = -1;
  MoveDestX = -1;
  MoveDestY = -1;
  
  int[] pos = getMotorPixelPos();
  
  Ani.to(this, 1, "MotorLocatorX", pos[0]);
  Ani.to(this, 1, "MotorLocatorY", pos[1]);

  //  if (debugMode) println("Motor X: " + MotorX + "  Motor Y: " + MotorY);
}