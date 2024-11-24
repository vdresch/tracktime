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
        skip_step = false;

        vibeData =  [new Attention.VibeProfile(100, 750)];

        // Gets pace and split info from user
        var pace_in_seconds = App.getApp().getProperty("pace");
        var split_distance = App.getApp().getProperty("split");

        // Turns pace (in seconds) to time intervals based on the split distance
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

    // Resets timer if there is a lap or the workout step is completed
    function reset_timer() as Void {

        var info = Activity.getActivityInfo();

        if (current_step_workout != null)
        {
            if(current_step_workout.intensity == 0)
            {
                running_laps++;
            }
        }

        last_lap = info.timerTime;
        split_laps = 1;
    }

    // Function called lap button is pressed. Resets timer
    function onTimerLap() as Void {
        reset_timer();
    }

    // Function called once workout step is completed. Resets timer
    function onWorkoutStepComplete() as Void {
        reset_timer();
    }

    function compute(info) as Void {

        current_step_workout = Activity.getCurrentWorkoutStep();

        // Sets flag so buzzer skips non running steps (warm up and cool down as well)
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

        timer = info.timerTime - last_lap;

        // Buzz if it's time to buzz. Adds 1 to split_laps so it buzzes only on the next split.
        if ((((timer+500)/1000 )>= (split_in_seconds * split_laps)) & !skip_step) {
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

        var info = Activity.getActivityInfo();
        timer = info.timerTime - last_lap;

        // Format time
        if (timer != null && timer > 0) {
            var hours = null;
            var minutes = timer / 1000 / 60;
            var seconds = (timer+500) / 1000 % 60;
            
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

        // Buzz if it's time to buzz. Adds 1 to split_laps so it buzzes only on the next split.
        if ((((timer+500)/1000 )>= (split_in_seconds * split_laps)) & !skip_step) {
            Attention.vibrate(vibeData);
            split_laps++;
        }

        value.setText(timer_display);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
