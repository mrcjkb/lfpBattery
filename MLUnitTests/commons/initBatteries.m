function [b] = initBatteries(d, c);
% d = dischargeCurves object
import lfpBattery.*
for i = 1:3
    b(i) = batteryCell(3, 3, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
    b(i).addcurves(d)
    b(i).addcurves(c, 'charge')
end
for i = 4:6
    b(i) = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
    b(i).addcurves(d)
    b(i).addcurves(c, 'charge')
end
for i = 7:9
    b(i) = batteryCell(3, 3, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
    b(i).addcurves(d)
    b(i).addcurves(c, 'charge')
end
end