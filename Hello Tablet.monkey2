'==============================================================
' Hello Tablet - Simple Tablet API Test
' Implementation: iDkP from GaragePixel
' 2025-03-17 13:57:19
' Aida 4
'==============================================================

#Import "<stdlib>"
#Import "<sdk_mojo>"

Using stdlib..
Using sdk_mojo..

'--------------------------------------------------------------
' Main Application
'--------------------------------------------------------------
Class TabletTestApp Extends sdk_mojo.m2.app.Window
	Field tablet:stdlib.io.tablet.api.TabletManager
	Field tabletAvailable:Bool = False
	Field drawing:Bool = False
	Field lastX:Float
	Field lastY:Float
	Field lastPressure:Float
	
	Method New()
		Super.New("Hello Tablet", 800, 600)
		
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
		
		' Clear with background color
		canvas.Color = New Color(0.15, 0.15, 0.15)
		canvas.DrawRect(0, 0, Width, Height)
		
		' Process input (tablet or mouse)
		If tabletAvailable
			tablet.Update()
			
			If tablet.GetPressure() > 0.01
				Local x:Float = tablet.GetX()
				Local y:Float = tablet.GetY()
				Local pressure:Float = tablet.GetPressure()
				
				' Draw a line from last position if drawing
				If drawing
					canvas.Color = New Color(1, 0.5, 0.2)
					canvas.LineWidth = 1 + pressure * 20
					canvas.DrawLine(lastX, lastY, x, y)
				End
				
				lastX = x
				lastY = y
				lastPressure = pressure
				drawing = True
			Else
				drawing = False
			End
		Else
			' Mouse fallback
			If Mouse.ButtonDown(MouseButton.Left)
				Local x:Float = Mouse.X
				Local y:Float = Mouse.Y
				Local pressure:Float = 1.0
				
				' Draw a line from last position if drawing
				If drawing
					canvas.Color = New Color(1, 0.5, 0.2)
					canvas.LineWidth = 10
					canvas.DrawLine(lastX, lastY, x, y)
				End
				
				lastX = x
				lastY = y
				lastPressure = pressure
				drawing = True
			Else
				drawing = False
			End
		End
		
		' Draw status info
		canvas.Color = New Color(1, 1, 1)
		canvas.LineWidth = 1
		
		If tabletAvailable
			canvas.DrawText("Tablet: " + tablet.GetDeviceName(), 10, 20)
			canvas.DrawText("Position: " + Int(tablet.GetX()) + ", " + Int(tablet.GetY()), 10, 40)
			canvas.DrawText("Pressure: " + String(tablet.GetPressure()), 10, 60)
		Else
			canvas.Color = New Color(1, 0.5, 0.5)
			canvas.DrawText("Tablet not available - using mouse fallback", 10, 20)
			canvas.DrawText("Position: " + Int(Mouse.X) + ", " + Int(Mouse.Y), 10, 40)
		End
		
		canvas.Color = New Color(0.8, 0.8, 0.8)
		canvas.DrawText("Press 'C' to clear canvas", 10, Height - 20)
		
		' Handle keyboard input
		If Keyboard.KeyHit(Key.C)
			' Clear is handled by redrawing the background on the next frame
		End
	End
End

'--------------------------------------------------------------
' Program Entry Point
'--------------------------------------------------------------
Function Main()
	New AppInstance
	New TabletTestApp
	App.Run()
End
