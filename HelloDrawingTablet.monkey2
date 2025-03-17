'==============================================================
' Simple Color Pencil with Mouse Wheel Size Control
' Implementation: iDkP from GaragePixel
' 2025-03-17 Aida 4
'==============================================================

#Import "<stdlib>"
#Import "<sdk_mojo>"

Using stdlib..
Using sdk_mojo..

'--------------------------------------------------------------
' ColorSwatch - Simple clickable color object
'--------------------------------------------------------------
Class ColorSwatch
	Field x:Float
	Field y:Float
	Field size:Float
	Field color:Color
	
	Method New(x:Float, y:Float, size:Float, color:Color)
		Self.x = x
		Self.y = y
		Self.size = size
		Self.color = color
	End
	
	Method Contains:Bool(px:Float, py:Float)
		Return px >= x And px < x + size And py >= y And py < y + size
	End
	
	Method Draw(canvas:Canvas, isSelected:Bool)
		canvas.Color = color
		canvas.DrawRect(x, y, size, size)
		
		If isSelected
			canvas.Color = New Color(1, 1, 1)
			canvas.DrawRect(x - 2, y - 2, size + 4, size + 4)
		End
	End
End

'--------------------------------------------------------------
' SimpleColorPencil - Main Application Class
'--------------------------------------------------------------
Class SimpleColorPencil Extends sdk_mojo.m2.app.Window
	' Drawing state
	Field canvas:Canvas          ' Main canvas
	Field drawImage:Image        ' Offscreen image for drawing
	Field drawCanvas:Canvas      ' Canvas for offscreen image
	Field tablet:stdlib.io.tablet.api.TabletManager
	Field tabletAvailable:Bool = False
	Field isDrawing:Bool = False
	Field lastX:Float = 0
	Field lastY:Float = 0
	Field pencilSize:Float = 5.0
	Field pencilColor:Color = New Color(0, 0, 0)
	
	' UI components
	Field colorSwatches:ColorSwatch[]
	Field selectedSwatch:Int = 0
	
	Method New()
		Super.New("Simple Color Pencil", 800, 600)
		
		' Create drawing surface
		drawImage = New Image(Width, Height - 50, PixelFormat.RGBA8, TextureFlags.Dynamic)
		drawCanvas = New Canvas(drawImage)
		drawCanvas.Color = New Color(1, 1, 1)
		drawCanvas.DrawRect(0, 0, Width, Height)
		drawCanvas.Flush()
		
		' Set up color swatches
		InitializeColorPalette()
		
		' Initialize tablet
		tablet = stdlib.io.tablet.api.TabletManager.GetInstance()
		tabletAvailable = tablet.Initialize()
		If Not tabletAvailable
			Print("Using mouse fallback")
		End
	End
	
	Method InitializeColorPalette()
		' Create basic color palette
		Local colors:Color[] = New Color[8]
		colors[0] = New Color(0, 0, 0)         ' Black
		colors[1] = New Color(1, 0, 0)         ' Red
		colors[2] = New Color(0, 0.7, 0)       ' Green
		colors[3] = New Color(0, 0, 1)         ' Blue
		colors[4] = New Color(1, 1, 0)         ' Yellow
		colors[5] = New Color(1, 0, 1)         ' Magenta
		colors[6] = New Color(0, 0.7, 0.7)     ' Cyan
		colors[7] = New Color(0.5, 0.5, 0.5)   ' Gray
		
		' Create swatch objects
		colorSwatches = New ColorSwatch[colors.Length]
		Local swatchSize:Float = 30
		Local startX:Float = 10
		Local y:Float = 10
		
		For Local i:Int = 0 Until colors.Length
			colorSwatches[i] = New ColorSwatch(startX + i * (swatchSize + 5), y, swatchSize, colors[i])
		Next
		
		pencilColor = colors[0]
	End
	
	Method OnRender(canvas:Canvas) Override
		App.RequestRender()
		
		' Handle input and drawing
		HandleInput()
		
		' Clear screen
		canvas.Color = New Color(0.9, 0.9, 0.9)
		canvas.DrawRect(0, 0, Width, Height)
		
		' Draw the drawing canvas
		canvas.Color = Color.White
		canvas.DrawImage(drawImage, 0, 50)
		
		' Draw UI
		DrawUI(canvas)
		
		canvas.Flush()
	End
	
	Method HandleInput()
		' Get input coordinates
		Local x:Float = 0
		Local y:Float = 0
		Local pressure:Float = 0
		
		If tabletAvailable
			tablet.Update()
			x = tablet.GetX()
			y = tablet.GetY() - 50  ' Adjust for UI area
			pressure = tablet.GetPressure()
		Else
			' Mouse fallback
			x = Mouse.X
			y = Mouse.Y - 50        ' Adjust for UI area
			pressure = Mouse.ButtonDown(MouseButton.Left) ? 1.0 Else 0.0
		End
		
		' Handle mouse wheel for pencil size
		Local wheelDelta:Int = Mouse.WheelY
		If wheelDelta <> 0
			pencilSize = Clamp(pencilSize + wheelDelta, 1.0, 50.0)
		End
		
		' Handle color swatch selection
		If Mouse.ButtonHit(MouseButton.Left) And Mouse.Y < 50
			For Local i:Int = 0 Until colorSwatches.Length
				If colorSwatches[i].Contains(Mouse.X, Mouse.Y)
					selectedSwatch = i
					pencilColor = colorSwatches[i].color
					Exit
				End
			Next
		End
		
		' Handle drawing
		If y >= 0 And pressure > 0.01
			Local strokeWidth:Float = pencilSize * (0.3 + pressure * 0.7)
			
			If Not isDrawing
				isDrawing = True
				lastX = x
				lastY = y
			Else
				drawCanvas.Color = pencilColor
				drawCanvas.LineWidth = strokeWidth
				drawCanvas.DrawLine(lastX, lastY, x, y)
				drawCanvas.Flush()
			End
			
			lastX = x
			lastY = y
		ElseIf isDrawing
			isDrawing = False
		End
		
		' Handle clear canvas with C key
		If Keyboard.KeyHit(Key.C)
			drawCanvas.Color = New Color(1, 1, 1)
			drawCanvas.DrawRect(0, 0, Width, Height)
			drawCanvas.Flush()
		End
	End
	
	Method DrawUI(canvas:Canvas)
		' Draw color swatches
		For Local i:Int = 0 Until colorSwatches.Length
			colorSwatches[i].Draw(canvas, i = selectedSwatch)
		Next
		
		' Draw pencil size indicator
		canvas.Color = New Color(0.2, 0.2, 0.2)
		canvas.DrawText("Size: " + Int(pencilSize), Width - 100, 15)
		canvas.Color = pencilColor
		canvas.DrawCircle(Width - 130, 20, pencilSize / 2)
		
		' Draw help text
		canvas.Color = New Color(0.3, 0.3, 0.3)
		canvas.DrawText("Mouse wheel: brush size | C: clear", 300, 15)
	End
End

'--------------------------------------------------------------
' Program Entry Point
'--------------------------------------------------------------
Function Main()
	New AppInstance
	New SimpleColorPencil
	App.Run()
End
