function circuitElementTests
%CIRCUITELEMENTTESTS Summary of this function goes here
%   Detailed explanation goes here
import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))
tol = 1e-10;

%% parallelElement tests
b = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.addcurves(d)
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElement(b);
p.addElement(b);
p.addElement(b);

assert(isequal(p.Cn, 3.*b.Cn), 'unexpected parallelElement nominal capacity')
assert(abs(p.Vn - b.Vn) < tol, 'unexpected parallelElement nominal voltage')
assert(isequal(p.Cd, 3.*b.Cd), 'parallelElement: unexpected discharge capacity')
assert(abs(p.V - b.V) < tol, 'parallelElement: unexpected voltage')

p.powerRequest(30, 60);

%% seriesElement tests
b = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.addcurves(d)
s = seriesElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElement(b)
s.addElement(b)
s.addElement(b)

assert(isequal(s.Cn, min(b.Cn)), 'unexpected seriesElement nominal capacity')
assert(abs(s.Vn - 3.*b.Vn) < tol, 'unexpected seriesElement nominal voltage')
assert(isequal(s.Cd, max(b.Cd)), 'seriesElement: unexpected discharge capacity')
assert(abs(s.V - 3.*b.V) < tol, 'seriesElement: unexpected voltage')

%% combination test 1
b = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.addcurves(d)
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElement(b);
p.addElement(b);
p.addElement(b);
s = seriesElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElement(p)
s.addElement(p)
s.addElement(p)

assert(abs(s.SoC - (1 - s.Cd ./ s.Cn)) < tol, 'SP: unexpected SoC')

s.powerRequest(100, 60); % MTODO: Requested power is still too high and sets negative powers if SoC is too close to upper limit



