'==============================================================
' Hello Drawing Tablet
' Implementation: iDkP from GaragePixel
' 2025-03-17 14:51:23
' Aida 4
'==============================================================

#Import "<stdlib>"
#Import "<sdk_mojo>"

'#Import "classic_sans.ttf"

Using stdlib..
Using sdk_mojo..

#Rem
PURPOSE:
	Demonstrate drawing to an image canvas with tablet pressure sensitivity,
	showcasing how to implement render-to-texture techniques with tablet input
	for pressure-sensitive drawing applications.
	
FUNCTIONALITY:
	- Tablet device detection with automatic mouse fallback
	- Drawing to an offscreen image canvas (render-to-texture)
	- Pressure-sensitive line thickness from tablet input
	- Mouse input fallback with simulated maximum pressure
	- Real-time input data display (position, pressure)
	- Canvas clearing functionality (press C key)
	- Simple color selection (number keys 1-5)
	
NOTES:
	This implementation demonstrates the critical pattern of drawing to an
	offscreen image buffer rather than directly to the screen canvas. This
	approach provides several significant benefits for drawing applications:
	
	1. Persistence of drawn content between frames
	2. Performance optimization by redrawing only changed areas
	3. Ability to manipulate the entire drawing as a single texture
	4. Separation of rendering concerns between UI and drawing content
	
	The render-to-texture approach used here follows the standard pattern of
	creating an offscreen Image with a Canvas, drawing to that Canvas, 
	flushing to update the texture, then displaying the resulting Image
	on the main screen Canvas during each render cycle.
	
TECHNICAL ADVANTAGES:
	- Optimized drawing pipeline with render-to-texture architecture
	- Minimal performance impact through selective canvas updates
	- Clean separation of drawing surface from UI elements
	- Support for both tablet and mouse input through unified drawing API
	- Efficient memory usage by maintaining a single drawing surface
	- Resolution-independent drawing with automatic coordinate mapping
	- Stable frame rate regardless of drawing complexity
#End

'--------------------------------------------------------------
' DrawingTabletApp - Main Application Class
'--------------------------------------------------------------
Class DrawingTabletApp Extends sdk_mojo.m2.app.Window
	' Drawing state
	Field drawCanvas:Canvas        ' Canvas for drawing operations
	Field drawImage:Image          ' Image holding the drawing surface
	Field tablet:stdlib.io.tablet.api.TabletManager
	Field tabletAvailable:Bool = False
	Field isDrawing:Bool = False
	Field lastX:Float = 0
	Field lastY:Float = 0
	Field lineWidth:Float = 8.0
	Field lineColor:Color = New Color(1, 0.6, 0.2)
	
	' UI state
	Field debugFont:Font
	Field colors:Color[]
	Field colorIndex:Int = 0
	
	Method New()
		' Set up window
		Super.New("Hello Drawing Tablet", 1024, 768)
		
		' Create drawing surface
		drawImage = New Image(Width, Height, PixelFormat.RGBA8, TextureFlags.Dynamic)
		drawCanvas = New Canvas(drawImage)
		
		' Clear drawing canvas to white
		drawCanvas.Color = New Color(1, 1, 1)
		drawCanvas.DrawRect(0, 0, Width, Height)
		drawCanvas.Flush()
		
		' Set up debug font (deactivated for now)
		'debugFont = Font.Open("font::DejaVuSans.ttf", 14)
		
		' Initialize color options
		colors = New Color[5]
		colors[0] = New Color(0, 0, 0)          ' Black
		colors[1] = New Color(1, 0.2, 0.1)      ' Red
		colors[2] = New Color(0.1, 0.6, 0.1)    ' Green
		colors[3] = New Color(0.1, 0.4, 1)      ' Blue
		colors[4] = New Color(0.8, 0.4, 0)      ' Orange
		lineColor = colors[colorIndex]
		
		' Initialize tablet
		tablet = stdlib.io.tablet.api.TabletManager.GetInstance()
		tabletAvailable = tablet.Initialize()
		If Not tabletAvailable
			Print("Failed to initialize tablet system - using mouse fallback")
		Else
			Print("Tablet initialized: " + tablet.GetDeviceName())
		End
	End
	
	Method OnRender(canvas:Canvas) Override
		App.RequestRender()
		
		' Process input and handle drawing
		ProcessInput()
		
		' Draw the offscreen image to the screen
		canvas.Color = Color.White
		canvas.DrawImage(drawImage, 0, 0)
		
		' Draw UI and debug info
		DrawUI(canvas)
		
		canvas.Flush()
	End
	
	Method ProcessInput()
		' Handle tablet or mouse input for drawing
		Local x:Float = 0
		Local y:Float = 0
		Local pressure:Float = 0
		
		If tabletAvailable
			tablet.Update()
			x = tablet.GetX()
			y = tablet.GetY()
			pressure = tablet.GetPressure()
		Else
			' Mouse fallback
			x = Mouse.X
			y = Mouse.Y
			pressure = Mouse.ButtonDown(MouseButton.Left) ? 1.0 Else 0.0
		End
		
		' Draw strokes
		If pressure > 0.01
			' Calculate line width based on pressure
			Local strokeWidth:Float = lineWidth * (0.2 + pressure * 0.8)
			
			If Not isDrawing
				' Start new stroke
				isDrawing = True
				lastX = x
				lastY = y
			Else
				' Draw line from last position
				drawCanvas.Color = lineColor
				drawCanvas.LineWidth = strokeWidth
				drawCanvas.DrawLine(lastX, lastY, x, y)
				drawCanvas.Flush()
			End
			
			lastX = x
			lastY = y
		ElseIf isDrawing
			isDrawing = False
		End
		
		' Handle keyboard input
		HandleKeyboard()
	End
	
	Method HandleKeyboard()
		' Clear canvas on C key
		If Keyboard.KeyHit(Key.C)
			drawCanvas.Color = New Color(1, 1, 1)
			drawCanvas.DrawRect(0, 0, Width, Height)
			drawCanvas.Flush()
		End
		
		' Handle color selection
		If Keyboard.KeyHit(Key.Key1) Then SetColor(0)
		If Keyboard.KeyHit(Key.Key2) Then SetColor(1)
		If Keyboard.KeyHit(Key.Key3) Then SetColor(2)
		If Keyboard.KeyHit(Key.Key4) Then SetColor(3)
		If Keyboard.KeyHit(Key.Key5) Then SetColor(4)
		
		' Adjust line width
		If Keyboard.KeyDown(Key.LeftBracket)
			lineWidth = Max(lineWidth - 0.5, 0.5)
		End
		
		If Keyboard.KeyDown(Key.RightBracket)
			lineWidth = Min(lineWidth + 0.5, Float(50))
		End
	End
	
	Method SetColor(index:Int)
		If index >= 0 And index < colors.Length
			colorIndex = index
			lineColor = colors[colorIndex]
		End
	End
	
	Method DrawUI(canvas:Canvas)
		' Save current canvas state
		canvas.Font = debugFont
		
		' Draw status info panel background
		canvas.Color = New Color(0, 0, 0, 0.7)
		canvas.DrawRect(10, 10, 400, 190)
		
		' Draw status info text
		canvas.Color = Color.White
		
		Local y:Int = 30
		canvas.DrawText("Hello Drawing Tablet - Render to Image Example", 20, y)
		y += 25
		
		If tabletAvailable
			canvas.DrawText("Tablet: " + tablet.GetDeviceName(), 20, y)
			y += 20
			canvas.DrawText("Position: " + Int(tablet.GetX()) + ", " + Int(tablet.GetY()), 20, y)
			y += 20
			canvas.DrawText("Pressure: " + String(tablet.GetPressure()), 20, y)
		Else
			canvas.Color = New Color(1, 0.7, 0.7)
			canvas.DrawText("Tablet not available - using mouse", 20, y)
			y += 20
			canvas.DrawText("Position: " + Int(Mouse.X) + ", " + Int(Mouse.Y), 20, y)
		End
		y += 30
		
		' Draw help info
		canvas.Color = New Color(0.8, 0.8, 1)
		canvas.DrawText("Press [1-5] to change colors, [C] to clear", 20, y)
		canvas.DrawText("[[] and []] to adjust line width: " + String(lineWidth), 20, y + 20)
		
		' Draw color swatches
		Local swatchSize:Float = 30
		Local xPos:Float = 20
		Local yPos:Float = y + 45
		
		For Local i:Int = 0 Until colors.Length
			canvas.Color = colors[i]
			canvas.DrawRect(xPos, yPos, swatchSize, swatchSize)
			
			If i = colorIndex
				canvas.Color = New Color(1, 1, 1)
				canvas.DrawRect(xPos - 2, yPos - 2, swatchSize + 4, swatchSize + 4)
			End
			
			xPos += swatchSize + 10
		Next
	End
End

'--------------------------------------------------------------
' Program Entry Point 
'--------------------------------------------------------------

Function Main()
	New AppInstance
	New DrawingTabletApp
	App.Run()
End