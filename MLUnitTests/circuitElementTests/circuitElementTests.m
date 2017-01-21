function circuitElementTests
%CIRCUITELEMENTTESTS Summary of this function goes here
%   Detailed explanation goes here
import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))
tol = 1e-10;

%% parallelElement tests
[b, ~] = initBatteries(d);
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(b, b, b);

assert(isequal(p.Cn, 3.*b.Cn), 'unexpected parallelElement nominal capacity')
assert(abs(p.Vn - b.Vn) < tol, 'unexpected parallelElement nominal voltage')
assert(isequal(p.Cd, 3.*b.Cd), 'parallelElement: unexpected discharge capacity')
assert(abs(p.V - b.V) < tol, 'parallelElement: unexpected voltage')

p.powerRequest(30, 60);

%% seriesElementPE tests
[b, b2] = initBatteries(d);
B = [b; b2; b];
s = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(b, b2, b)

assert(isequal(s.Cn, min([B.Cn])), 'unexpected seriesElementPE nominal capacity')
assert(abs(s.Vn - sum([B.Vn])) < tol, 'unexpected seriesElementPE nominal voltage')
assert(isequal(s.Cd, max(b.Cd)), 'seriesElementPE: unexpected discharge capacity')
assert(abs(s.V - sum([B.V])) < tol, 'seriesElementPE: unexpected voltage')

%% seriesElementAE tests
[b, b2] = initBatteries(d);
s = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(b, b2, b)
B = [b; b2; b];

assert(isequal(s.Cn, mean([B.Cn])), 'unexpected seriesElementPE nominal capacity')
assert(abs(s.Vn - sum([B.Vn])) < tol, 'unexpected seriesElementPE nominal voltage')
assert(isequal(s.Cd, mean([B.Cd])), 'seriesElementPE: unexpected discharge capacity')
assert(abs(s.V - sum([B.V])) < tol, 'seriesElementPE: unexpected voltage')

%% String of parallel cells with passive equalization (SPP)
[b, b2] = initBatteries(d);
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(b, b2, b);
p2 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p2.addElements(b, b, b);
s = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(p, p2, p)
B = [b, b2, b; ...
     b, b, b; ...
     b, b2, b];
     
assert(abs(s.SoC - (1 - s.Cd ./ s.Cn)) < tol, 'SPP: unexpected SoC')
assert(isequal(s.Cn, min([sum([B(1,:).Cn]); sum([B(2,:).Cn]); sum([B(3,:).Cn])])), 'SPP: unexpected nominal capacity')
assert(isequal(s.Cd, min([sum([B(1,:).Cd]); sum([B(2,:).Cd]); sum([B(3,:).Cd])])), 'SPP: unexpected discharge capacity')
assert(isequal(s.Vn, sum([mean([B(1,:).Vn]); mean([B(2,:).Vn]); mean([B(3,:).Vn])])), 'SPP: unexpected nominal voltage')

chargeDischargeTest(s, 'SPP')

%% String of parallel cells with active equalization (SPA)
[b, b2] = initBatteries(d);
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(b, b2, b);
p2 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p2.addElements(b, b, b);
s = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(p, p2, p)
B = [b, b2, b; ...
     b, b, b; ...
     b, b2, b];

assert(abs(s.SoC - (1 - s.Cd ./ s.Cn)) < tol, 'SPA: unexpected SoC')
assert(isequal(s.Cn, mean([sum([B(1,:).Cn]); sum([B(2,:).Cn]); sum([B(3,:).Cn])])), 'SPA: unexpected nominal capacity')
assert(isequal(s.Vn, sum([mean([B(1,:).Vn]); mean([B(2,:).Vn]); mean([B(3,:).Vn])])), 'SPA: unexpected nominal voltage')

chargeDischargeTest(s, 'SPA')
% MTODO: Fix lower SoC limitation

%% Parallel strings of cells with passive equalization (PSP)
[b, b2] = initBatteries(d);
s = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(b, b2, b)
s2 = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s2.addElements(b, b, b)
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(s, s2, s);
B = [b, b, b; ...
    b2, b, b2; ...
    b, b, b];

assert(abs(p.SoC - (1 - p.Cd ./ p.Cn)) < tol, 'PSP: unexpected SoC')
assert(isequal(p.Cn, sum([min([B(:,1).Cn]); min([B(:,2).Cn]); min([B(:,3).Cn])])), 'PSP: unexpected nominal capacity')
assert(isequal(p.Vn, mean([sum([B(:,1).Vn]); sum([B(:,2).Vn]); sum([B(:,3).Vn])])), 'PSP: unexpected nominal voltage')
chargeDischargeTest(p, 'PSP')


%% Parallel strings of cells with active equalization (PSA)
[b, b2] = initBatteries(d);
s = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(b, b2, b)
s2 = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s2.addElements(b, b, b)
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(s, s2, s)
B = [b, b, b;...
    b2, b, b2; ...
    b, b, b];

assert(abs(p.SoC - (1 - p.Cd ./ p.Cn)) < tol, 'PSA: unexpected SoC')
assert(isequal(p.Cn, sum([mean([B(:,1).Cn]); mean([B(:,2).Cn]); mean([B(:,3).Cn])])), 'PSA: unexpedced nominal capacity')
assert(isequal(p.Vn, mean([sum([B(:,1).Vn]); sum([B(:,2).Vn]); sum([B(:,3).Vn])])), 'PSA: unexpected nominal voltage')
chargeDischargeTest(p, 'PSA')

%%
disp('Circuit element tests passed.')


end

function [b, b2] = initBatteries(d)
% d = dischargeCurves object
import lfpBattery.*
b = batteryCell(3, 3, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b2 = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.addcurves(d)
b2.addcurves(d)
end

function chargeDischargeTest(b, config)
% config = topology name as string
tol = 0.011;
for i = 1:100
    P = b.powerRequest(100, 60);
end
assert(isequal(P, 0), [config, ': Unexpected charging behaviour (Power)'])
assert(isequal(b.SoC, 1), [config, ': Unexpected charging behaviour (SoC)'])
for i = 1:100
    P = b.powerRequest(-100, 60);
end
assert(isequal(P, 0), [config, ': Unexpected discharging behaviour (Power)'])
assert(abs(b.SoC - 0.2) < tol, [config, ': Unexpected discharging behaviour (SoC)'])
end
