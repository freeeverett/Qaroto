package main

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"github.com/freeeverett/qaroto/internal/ui"
)

func main() {
	// Create new application
	a := app.New()
	a.Settings().SetTheme(nil) // Use default theme
	
	// Create main window
	w := a.NewWindow("Qaroto - Crypto Trading Interface")
	w.Resize(fyne.NewSize(900, 700))
	w.CenterOnScreen()
	
	// Create and setup the UI
	appUI := ui.NewApp(w)
	_ = appUI // Use the app UI instance
	
	// Show and run
	w.ShowAndRun()
}
