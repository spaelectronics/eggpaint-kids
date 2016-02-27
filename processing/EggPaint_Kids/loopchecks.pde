/**
 * EggPaint Kids - Draw loop check functions (not for drawing)
 */


// Manage checking if the brush needs servicing, and moving to the next path
void checkServiceBrush() {

  if (serviceBrush() == false)

    if (millis() > NextMoveTime)
    {

      boolean actionItem = false;
      int intTemp = -1;


      if ((ToDoList.length > (indexDone + 1))   && ((Paused == false) || (replayIsRunning == true)))
      {
        actionItem = true;
        intTemp = ToDoList[1 + indexDone];

        indexDone++;

        if ((ToDoList.length <= (indexDone + 1))   && (replayIsRunning == true))
        {
          replayIsRunning = false;
          printButton.displayColor = TextColor;
          printButton.highlightColor = TextHighLight;
          printButton.label = "Print Egg";
          redrawButtons();
        }
        
        if ((ToDoList.length <= (indexDone + 1))   && (clearIsRunning == true))
        {
          clearIsRunning = false;
          pause();
        }
      }


      if (actionItem)
      {  // Perform next action from ToDoList::

        if (segmentQueued)
          drawQueuedSegment();  // Draw path segment to screen

        if (intTemp >= 0)
        { // Move the carriage to paint a path segment!  ("This is where the magic happens....")

          int x2 = floor(intTemp / 10000);
          int y2 = intTemp - 10000 * x2;

          int x1 = round( float(x2 - MousePaperLeft) * MotorStepsPerPixel + xMotorPaperOffset);
          int y1 = round( float(y2 - MousePaperTop) * MotorStepsPerPixel);

          MoveToXY(x1, y1);

          if (BrushDown == true) { 
            if (lastPosition == -1)
              lastPosition = intTemp;
            queueSegmentToDraw(lastPosition, intTemp);
            lastPosition = intTemp;
          }

          /*
           IF next item in ToDoList is ALSO a move, then calculate the next move and queue it to the EBB at this time.
           Save the duration of THAT move as "SubsequentWaitTime."
           
           When the first (pre-existing) move completes, we will check to see if SubsequentWaitTime is defined (i.e., >= 0).
           If SubsequentWaitTime is defined, then (1) we add that value to the NextMoveTime:
         
           NextMoveTime = millis() + SubsequentWaitTime;
           SubsequentWaitTime = -1;
           
           We also (2) queue up that segment to be drawn.
           
           We also (3) queue up the next move, if there is one that could be queued.  We do
           
           */
        }
        else
        {
          lastPosition = -1;  // For drawing

          intTemp = -1 * intTemp;

          if ((intTemp > 9) && (intTemp < 20))
          {  // Change paint color
            intTemp -= 10;
            getPaint(intTemp);
          }
          else if (intTemp == 30)
          {
            raiseBrush();
          }
          else if (intTemp == 31)
          {
            lowerBrush();
          }
          else if (intTemp == 35)
          {
            MoveToXY(0, 0);
          }
        }
      }
    }
}

// Manage checking mouse position for highlights
void checkHighlights() {
  boolean doHighlightRedraw = false;
  int i;
  float tempFloat;

  if (recordingGesture == false) {
    int x2 = -1;

    if ((mouseX > paintSwatchX - (paintSwatchOvalWidth /2) ) &&
      (mouseX < paintSwatchX + (paintSwatchOvalWidth / 2)))
    {   // Check for mouse over paint swatches:

      for ( i = 0; i < 8; i++) {
        tempFloat = paintSwatchY0 + i * paintSwatchyD - ( paintSwatchOvalheight / 2);
        if ((mouseY > tempFloat ) && (mouseY < (tempFloat + paintSwatchOvalheight)))
        {
          x2 = i;
          break;
        }
      }
    }

    if (x2 != highlightedColor)
    {
      doHighlightRedraw = true;
      highlightedColor = x2;
    }
  }


  // Manage highlighting of text buttons
  if ((mouseY >= MousePaperBottom)  || (mouseY < MousePaperTop))
  {
    if ((mouseY <= height)  && (mouseX >=  (MousePaperLeft - 50)))
    {
      redrawButtons();
    }
  }


  if (doHighlightRedraw) {
    redrawHighlight();
  }
}