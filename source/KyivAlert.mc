import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:background)
class KyivAlertService extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        try {
            Communications.makeWebRequest(
                "https://tryvoha.online/api/v1/alerts/kyiv",
                null,
                {:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON},
                method(:onResponse));
        } catch (e) {
            Background.exit([0, 0]);
        }
    }

    function onResponse(code as Number, data as Dictionary or String or Null) as Void {
        if (code != 200 || !(data instanceof Dictionary)) {
            Background.exit([0, 0]);
            return;
        }

        var slug = data.get("slug");
        if (!(slug instanceof String) || !slug.equals("kyiv")) {
            Background.exit([0, 0]);
            return;
        }
        var timestamp = data.get("updated_at");
        var active = data.get("active");
        var level = data.get("level");
        var status = 0;
        if (active == false && level == null && data.get("active_anywhere") == false) {
            status = 1;
        } else if (active == true && level instanceof String) {
            if (level.equals("yellow")) {
                status = 2;
            } else if (level.equals("red")) {
                status = 3;
            }
        }
        if (status == 0 || !(timestamp instanceof String)) {
            Background.exit([0, 0]);
            return;
        }

        var updated = utcTimestamp(timestamp);
        Background.exit([status, updated]);
    }

    private function utcTimestamp(value as String) as Number {
        if (value.length() < 20 || !(value.substring(value.length() - 1, value.length()) as String).equals("Z")
            || !(value.substring(4, 5) as String).equals("-") || !(value.substring(7, 8) as String).equals("-")
            || !(value.substring(10, 11) as String).equals("T") || !(value.substring(13, 14) as String).equals(":")
            || !(value.substring(16, 17) as String).equals(":")) {
            return 0;
        }
        var year = (value.substring(0, 4) as String).toNumber();
        var month = (value.substring(5, 7) as String).toNumber();
        var day = (value.substring(8, 10) as String).toNumber();
        var hour = (value.substring(11, 13) as String).toNumber();
        var minute = (value.substring(14, 16) as String).toNumber();
        var second = (value.substring(17, 19) as String).toNumber();
        if (year == null || month == null || day == null || hour == null || minute == null || second == null
            || year < 2020 || year > 2099 || month < 1 || month > 12 || day < 1 || day > 31
            || hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) {
            return 0;
        }
        return Gregorian.moment({:year => year, :month => month, :day => day,
            :hour => hour, :minute => minute, :second => second}).value();
    }
}
