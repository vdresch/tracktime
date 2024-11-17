using Toybox.Application as App;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Math;

class TrackTimeView extends WatchUi.DataField {

    hidden var timer = 0;
    hidden var last_lap = 0;
    hidden var lap_trigger as Boolean;
    hidden var split_in_seconds as Numeric;
    hidden var split_laps as Numeric;
    hidden var current_step_workout;
    hidden var skip_step as Boolean;
    hidden var running_laps = 0;
    hidden var timer_display;
    hidden var vibeData;

    function initialize() {
        DataField.initialize();

        split_laps = 1;
        lap_trigger = false;
        skip_step = false;

        vibeData =  [new Attention.VibeProfile(100, 650)];

        var pace_in_seconds = App.getApp().getProperty("pace");
        var split_distance = App.getApp().getProperty("split");

        split_in_seconds = pace_in_seconds / (1000/split_distance);

    }

    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label") as Text;
            labelView.locY = labelView.locY - 28;
            var valueView = View.findDrawableById("value") as Text;
            valueView.locY = valueView.locY + 13;
        }

        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    function onTimerLap() as Void {
        lap_trigger = true;
    }

    function onWorkoutStepComplete() as Void {
        lap_trigger = true;
    }

    function compute(info) as Void {

        current_step_workout = Activity.getCurrentWorkoutStep();

        if (current_step_workout != null)
        {
            if(current_step_workout.intensity == 0)
            {
                skip_step = false;
            }
            else {
                skip_step = true;
            }
        }

        if (lap_trigger) {

            if (current_step_workout != null)
            {
                if(current_step_workout.intensity == 0)
                {
                    running_laps++;
                }
            }

            lap_trigger = false;
            last_lap = info.timerTime;
            split_laps = 1;
        }


        timer = info.timerTime - last_lap;

        if ((((timer+400)/1000 )>= (split_in_seconds * split_laps)) & !skip_step) {
            System.println("100m");
            Attention.vibrate(vibeData);
            split_laps++;
        }
    }

    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }

        // Format time
        if (timer != null && timer > 0) {
            var hours = null;
            var minutes = timer / 1000 / 60;
            var seconds = (timer+300) / 1000 % 60;
            
            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes % 60;
            }
            
            if (hours == null) {
                timer_display = minutes.format("%d") + ":" + seconds.format("%02d");
            } else {
                timer_display = hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
            }
        } else {
            timer_display = "0:00";
        } 

        //value.setText(timer.toString());

        value.setText(timer_display);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
