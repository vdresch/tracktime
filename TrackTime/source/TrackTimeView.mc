using Toybox.Application as App;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Math;

class TrackTimeView extends WatchUi.DataField {

    var timer = 0;
    var timer_aux = 0;
    var last_lap = 0;
    var split_in_seconds as Numeric;
    var split_laps as Numeric;
    var current_step_workout;
    var skip_step as Boolean;
    var running_laps = 0;
    var timer_display;
    var last_lap_display;
    var show_last_lap = false;
    var vibeData;

    function initialize() {
        DataField.initialize();

        split_laps = 1;
        skip_step = App.getApp().getProperty("workout_only") == 1;

        vibeData =  [new Attention.VibeProfile(100, 750)];

        // Gets pace and split info from user
        var pace_in_seconds = App.getApp().getProperty("pace");
        var split_distance = App.getApp().getProperty("split");

        // Turns pace (in seconds) to time intervals based on the split distance
        split_in_seconds = pace_in_seconds / (1000/split_distance);

    }

    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // If not full screen
        if (obscurityFlags != 15) {
            View.setLayout(Rez.Layouts.SmallLayout(dc));
            var labelView = View.findDrawableById("label") as Text;
            labelView.locY = labelView.locY - 32;
            var valueView = View.findDrawableById("value") as Text;
            valueView.locY = valueView.locY + 25;
            show_last_lap = false;
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label") as Text;
            labelView.locY = labelView.locY - 32;
            var valueView = View.findDrawableById("value") as Text;
            valueView.locY = valueView.locY + 13;
            var valueView2 = View.findDrawableById("value2") as Text;
            valueView2.locY = valueView2.locY + 17;
            (View.findDrawableById("label2") as Text).setText(Rez.Strings.label2);
            show_last_lap = true;
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

        last_lap = info.timerTime - timer_aux;
        timer_aux = info.timerTime;
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

        timer = info.timerTime - timer_aux;

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
        timer = info.timerTime - timer_aux;

        // Format and show timer
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
         
        value.setText(timer_display);

        // Shows last lap
        if (show_last_lap) {

            var value2 = View.findDrawableById("value2") as Text;
            if (getBackgroundColor() == Graphics.COLOR_BLACK) {
                value2.setColor(Graphics.COLOR_WHITE);
            } else {
                value2.setColor(Graphics.COLOR_BLACK);
            }
            
            if (last_lap != null && last_lap > 0) {

                var hours = null;
                var minutes = last_lap / 1000 / 60;
                var seconds = (last_lap+500) / 1000 % 60;
                
                if (minutes >= 60) {
                    hours = minutes / 60;
                    minutes = minutes % 60;
                }
                
                if (hours == null) {
                    last_lap_display = minutes.format("%d") + ":" + seconds.format("%02d");
                } else {
                    last_lap_display = hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
                }
            } else {
                last_lap_display = "No Laps";
            }
            
            value2.setText(last_lap_display);
        }

        // Buzz if it's time to buzz. Adds 1 to split_laps so it buzzes only on the next split.
        if ((((timer+500)/1000 )>= (split_in_seconds * split_laps)) & !skip_step) {
            Attention.vibrate(vibeData);
            split_laps++;
        }

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
