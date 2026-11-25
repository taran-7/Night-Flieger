import Toybox.Application;
import Toybox.Background;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

(:background)
class FliegerApp extends Application.AppBase {
    private var _kyivAlert as Array<Number>?;
    function initialize() {
        AppBase.initialize();
    }

    (:typecheck(disableBackgroundCheck))
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        _kyivAlert = Application.Storage.getValue("kyivAlert") as Array<Number>?;
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(300));
        }
        return [new FliegerView()];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new KyivAlertService()];
    }

    function onBackgroundData(data as Application.PersistableType) as Void {
        _kyivAlert = data as Array<Number>;
        Application.Storage.setValue("kyivAlert", data as Array<Application.Storage.ValueType>);
        WatchUi.requestUpdate();
    }

    function kyivAlertStatus(now as Number) as Number {
        var alert = _kyivAlert;
        if (alert == null || alert[1] == 0) {
            return 0;
        }
        // Use the source timestamp so a cached HTTP response cannot refresh old data.
        var age = now - alert[1];
        return age < -30 || age > 420 ? 0 : alert[0];
    }
}

class FliegerView extends WatchUi.WatchFace {
    private const INK = 0x08090a;
    private const CREAM = 0xeeeade;
    private const MUTED = 0xa9aca1;
    private const RED = 0xee0024;
    private const DIM = 0x55534c;
    private const READOUT_OFFSET = 74;
    private const READOUT_Y = 265;
    private const DEG = Math.PI / 180.0;

    private var _sleeping as Boolean = false;
    private var _centerX as Number = 227;
    private var _centerY as Number = 227;

    private var _alwaysOnTimeFont as FontResource;
    private var _detailFont as FontResource;
    private var _largeChargeFont as FontResource;
    private var _chargeFont as FontResource;
    private var _batteryFont as FontResource;

    function initialize() {
        WatchFace.initialize();
        _alwaysOnTimeFont = WatchUi.loadResource(Rez.Fonts.AlwaysOnTimeFont) as FontResource;
        _detailFont = WatchUi.loadResource(Rez.Fonts.DetailFont) as FontResource;
        _largeChargeFont = WatchUi.loadResource(Rez.Fonts.LargeChargeFont) as FontResource;
        _chargeFont = WatchUi.loadResource(Rez.Fonts.ChargeFont) as FontResource;
        _batteryFont = WatchUi.loadResource(Rez.Fonts.BatteryFont) as FontResource;
    }

    function onEnterSleep() as Void {
        _sleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _sleeping = false;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var now = Time.now();
        var local = Gregorian.info(now, Time.FORMAT_SHORT);
        var alert = (Application.getApp() as FliegerApp).kyivAlertStatus(now.value());
        _centerX = dc.getWidth() / 2;
        _centerY = dc.getHeight() / 2;
        var battery = 0;
        if (_sleeping) {
            // Move the sparse display each minute to protect the AMOLED panel.
            _centerX += (local.min % 3 - 1) * 9;
            _centerY += ((local.min * 2) % 3 - 1) * 9;
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            for (var marker = 0; marker < 4; marker++) {
                tick(dc, _centerX, _centerY, marker * 90, 197, 211, DIM, 2);
            }
            drawHourNumbers(dc, Graphics.FONT_MEDIUM, DIM, true);
        } else {
            dc.setColor(INK, INK);
            dc.clear();
            drawDial(dc);
            battery = Math.round(System.getSystemStats().battery).toNumber();
            drawBatteryScale(dc, battery);
        }

        var hourAngle = (local.hour % 12) * 30 + local.min * 0.5;
        var minuteAngle = local.min * 6;
        if (_sleeping) {
            tick(dc, _centerX, _centerY, hourAngle, 0, 105, 0xdfb829, 8);
            tick(dc, _centerX, _centerY, minuteAngle, 0, 145, 0x3984db, 6);
            var hour = local.hour;
            if (!System.getDeviceSettings().is24Hour) {
                hour = (hour + 11) % 12 + 1;
            }
            var time = hour.toString() + ":" + local.min.format("%02d");
            drawAlertTime(dc, _centerX, _centerY, _alwaysOnTimeFont, time, alert);
            return;
        }

        hand(dc, hourAngle, 115, 11, 23, 20);
        hand(dc, minuteAngle, 153, 8, 20, 26);
        tick(dc, _centerX, _centerY, local.sec * 6, -33, 187, RED, 2);
        dc.setColor(0x171918, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, 8);
        dc.setColor(RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, 4);

        var weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var date = weekdays[(local.day_of_week as Number) - 1] + " " + local.day.format("%02d");
        legibleLabel(dc, _centerX, 141, _detailFont, date, CREAM);
        var chargeFont = battery < 100 ? _largeChargeFont : _chargeFont;
        legibleLabel(dc, _centerX - READOUT_OFFSET, READOUT_Y, chargeFont, battery.toString(), CREAM);
        label(dc, _centerX - READOUT_OFFSET, READOUT_Y + 26, _batteryFont, "BAT", MUTED);
        drawAlertTime(dc, _centerX + READOUT_OFFSET, READOUT_Y, Graphics.FONT_LARGE, local.min.toString(), alert);
    }

    private function drawAlertTime(dc as Dc, x as Number, y as Number, font as FontType,
        value as String, alert as Number) as Void {
        var color = Graphics.COLOR_WHITE as Number;
        if (alert == 2) {
            color = 0xffdc26;
        } else if (alert == 3) {
            color = 0xff343d;
        }
        legibleLabel(dc, x, y, font, value, color);
        if (alert == 0) {
            var digit = value.substring(value.length() - 1, value.length());
            var width = dc.getTextWidthInPixels(value, font);
            dc.setColor(0xff9124, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x - width / 2 + width, y, font, digit,
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function legibleLabel(dc as Dc, x as Number, y as Number, font as FontType,
        value as String, color as Number) as Void {
        // Keep the text legible where a hand's outline crosses it.
        var background = _sleeping ? Graphics.COLOR_BLACK : INK;
        label(dc, x - 1, y, font, value, background);
        label(dc, x + 1, y, font, value, background);
        label(dc, x, y - 1, font, value, background);
        label(dc, x, y + 1, font, value, background);
        label(dc, x, y, font, value, color);
    }

    private function drawDial(dc as Dc) as Void {
        dc.setPenWidth(1);
        dc.setColor(0x343835, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_centerX, _centerY, 220);
        for (var mark = 0; mark < 60; mark++) {
            var major = mark % 5 == 0;
            tick(dc, _centerX, _centerY, mark * 6, major ? 197 : 204, 211,
                major ? CREAM : MUTED, major ? 3 : 1);
        }
        dc.setColor(CREAM, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[_centerX, 41], [_centerX - 13, 64], [_centerX + 13, 64]]);
        dc.fillCircle(_centerX - 22, 57, 3);
        dc.fillCircle(_centerX + 22, 57, 3);
        drawHourNumbers(dc, Graphics.FONT_LARGE, CREAM, false);
    }

    private function drawHourNumbers(dc as Dc, font as FontType, color as Number,
        showTwelve as Boolean) as Void {
        var lastHour = showTwelve ? 12 : 11;
        for (var hour = 1; hour <= lastHour; hour++) {
            var angle = hour * 30 * DEG;
            label(dc, (_centerX + 166 * Math.sin(angle)).toNumber(),
                (_centerY - 166 * Math.cos(angle)).toNumber(), font, hour.toString(), color);
        }
    }

    private function drawBatteryScale(dc as Dc, battery as Number) as Void {
        var x = _centerX - READOUT_OFFSET;
        var y = READOUT_Y;
        dc.setPenWidth(1);
        dc.setColor(0x42463f, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, 52);
        var chargeColor = 0xa3323b;
        if (battery >= 60) {
            chargeColor = 0x44a66a;
        } else if (battery >= 30) {
            chargeColor = 0xb18b24;
        }
        for (var mark = 0; mark < 100; mark++) {
            tick(dc, x, y, mark * 3.6, 42, 46, mark < battery ? chargeColor : 0x2a2d2a, 1);
        }
    }

    private function label(dc as Dc, x as Number, y as Number, font as FontType,
        value as String, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, value, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function tick(dc as Dc, x as Number, y as Number, degrees as Numeric,
        innerRadius as Number, outerRadius as Number, color as Number, width as Number) as Void {
        var sine = Math.sin(degrees * DEG);
        var cosine = Math.cos(degrees * DEG);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(width);
        dc.drawLine((x + innerRadius * sine).toNumber(), (y - innerRadius * cosine).toNumber(),
            (x + outerRadius * sine).toNumber(), (y - outerRadius * cosine).toNumber());
    }

    private function hand(dc as Dc, degrees as Numeric, length as Number, halfWidth as Number,
        tip as Number, tail as Number) as Void {
        var sine = Math.sin(degrees * DEG);
        var cosine = Math.cos(degrees * DEG);
        var points = [
            handPoint(0, length, sine, cosine),
            handPoint(halfWidth, length - tip, sine, cosine),
            handPoint(halfWidth, -tail, sine, cosine),
            handPoint(-halfWidth, -tail, sine, cosine),
            handPoint(-halfWidth, length - tip, sine, cosine)
        ];
        dc.setColor(CREAM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < points.size(); i++) {
            var from = points[i];
            var to = points[(i + 1) % points.size()];
            dc.drawLine(from[0], from[1], to[0], to[1]);
        }
    }

    private function handPoint(across as Number, forward as Number, sine as Float or Double,
        cosine as Float or Double) as [Number, Number] {
        return [(_centerX + across * cosine + forward * sine).toNumber(),
            (_centerY + across * sine - forward * cosine).toNumber()];
    }
}
