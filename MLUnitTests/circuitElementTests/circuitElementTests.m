function circuitElementTests
%CIRCUITELEMENTTESTS Summary of this function goes here
%   Detailed explanation goes here
import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))
tol = 1e-10;

%% parallelElement tests
b = initBatteries(d);
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
B = b(1:3);
p.addElements(B);


assert(isequal(p.Cn, sum([B.Cn])), 'unexpected parallelElement nominal capacity')
assert(isequal(p.Vn, mean([B.Vn])), 'unexpected parallelElement nominal voltage')
assert(isequal(p.Cd, sum([B.Cd])), 'parallelElement: unexpected discharge capacity')
assert(isequal(p.V, mean([B.V])), 'parallelElement: unexpected voltage')

p.powerRequest(30, 60);

%% seriesElementPE tests
b = initBatteries(d);
B = [b(1); b(4); b(7)];
s = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(B)

assert(isequal(s.Cn, min([B.Cn])), 'unexpected seriesElementPE nominal capacity')
assert(abs(s.Vn - sum([B.Vn])) < tol, 'unexpected seriesElementPE nominal voltage')
assert(isequal(s.Cd, min([B.Cd])), 'seriesElementPE: unexpected discharge capacity')
assert(abs(s.V - sum([B.V])) < tol, 'seriesElementPE: unexpected voltage')

%% seriesElementAE tests
b = initBatteries(d);
B = [b(1); b(4); b(7)];
s = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(B)

assert(isequal(s.Cn, mean([B.Cn])), 'unexpected seriesElementPE nominal capacity')
assert(abs(s.Vn - sum([B.Vn])) < tol, 'unexpected seriesElementPE nominal voltage')
assert(isequal(s.Cd, mean([B.Cd])), 'seriesElementPE: unexpected discharge capacity')
assert(abs(s.V - sum([B.V])) < tol, 'seriesElementPE: unexpected voltage')

%% String of parallel cells with passive equalization (SPP)
B = initBatteries(d);
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(B(1:3))
p2 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p2.addElements(B(4:6))
p3 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p3.addElements(B(7:9))
s = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(p, p2, p3)
B = [B(1:3); B(4:6); B(7:9)];

assert(abs(s.SoC - (1 - s.Cd ./ s.Cn)) < tol, 'SPP: unexpected SoC')
assert(isequal(s.Cn, min([sum([B(1,:).Cn]); sum([B(2,:).Cn]); sum([B(3,:).Cn])])), 'SPP: unexpected nominal capacity')
assert(isequal(s.Cd, min([sum([B(1,:).Cd]); sum([B(2,:).Cd]); sum([B(3,:).Cd])])), 'SPP: unexpected discharge capacity')
assert(isequal(s.Vn, sum([mean([B(1,:).Vn]); mean([B(2,:).Vn]); mean([B(3,:).Vn])])), 'SPP: unexpected nominal voltage')

chargeDischargeTest(s, 'SPP')

%% String of parallel cells with active equalization (SPA)
B = initBatteries(d);
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(B(1:3));
p2 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p2.addElements(B(4:6));
p3 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p3.addElements(B(7:9));
s = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(p, p2, p3)
B = [B(1:3); B(4:6); B(7:9)];

assert(abs(s.SoC - (1 - s.Cd ./ s.Cn)) < tol, 'SPA: unexpected SoC')
assert(isequal(s.Cn, mean([sum([B(1,:).Cn]); sum([B(2,:).Cn]); sum([B(3,:).Cn])])), 'SPA: unexpected nominal capacity')
assert(isequal(s.Vn, sum([mean([B(1,:).Vn]); mean([B(2,:).Vn]); mean([B(3,:).Vn])])), 'SPA: unexpected nominal voltage')

chargeDischargeTest(s, 'SPA')

%% Parallel strings of cells with passive equalization (PSP)
B = initBatteries(d);
s = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(B(1:3))
s2 = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s2.addElements(B(4:6))
s3 = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s3.addElements(B(7:9))
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(s, s2, s3);
B = [B(1) B(4) B(7); B(2) B(5) B(8); B(3) B(6) B(9)];

assert(abs(p.SoC - (1 - p.Cd ./ p.Cn)) < tol, 'PSP: unexpected SoC')
assert(isequal(p.Cn, sum([min([B(:,1).Cn]); min([B(:,2).Cn]); min([B(:,3).Cn])])), 'PSP: unexpected nominal capacity')
assert(isequal(p.Vn, mean([sum([B(:,1).Vn]); sum([B(:,2).Vn]); sum([B(:,3).Vn])])), 'PSP: unexpected nominal voltage')
chargeDischargeTest(p, 'PSP')


%% Parallel strings of cells with active equalization (PSA)
B = initBatteries(d);
s = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s.addElements(B(1:3))
s2 = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s2.addElements(B(4:6))
s3 = seriesElementAE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
s3.addElements(B(7:9))
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(s, s2, s3);
B = [B(1) B(4) B(7); B(2) B(5) B(8); B(3) B(6) B(9)];

assert(abs(p.SoC - (1 - p.Cd ./ p.Cn)) < tol, 'PSA: unexpected SoC')
assert(isequal(p.Cn, sum([mean([B(:,1).Cn]); mean([B(:,2).Cn]); mean([B(:,3).Cn])])), 'PSA: unexpedced nominal capacity')
assert(isequal(p.Vn, mean([sum([B(:,1).Vn]); sum([B(:,2).Vn]); sum([B(:,3).Vn])])), 'PSA: unexpected nominal voltage')
chargeDischargeTest(p, 'PSA')

%%
disp('Circuit element tests passed.')


end

function [b] = initBatteries(d)
% d = dischargeCurves object
import lfpBattery.*
for i = 1:3
    b(i) = batteryCell(3, 3, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
    b(i).addcurves(d)
end
for i = 4:6
    b(i) = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
    b(i).addcurves(d)
end
for i = 7:9
    b(i) = batteryCell(3, 3, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
    b(i).addcurves(d)
end
end

function chargeDischargeTest(b, config)
% config = topology name as string
tol = 1e-6;
for i = 1:100
    P = b.powerRequest(100, 60);
end
assert(isequal(P, 0), [config, ': Unexpected charging behaviour (Power)'])
assert(abs(b.SoC - 1) < tol, [config, ': Unexpected charging behaviour (SoC)'])
for i = 1:100
    P = b.powerRequest(-100, 60);
end
assert(isequal(P, 0), [config, ': Unexpected discharging behaviour (Power)'])
assert(abs(b.SoC - 0.2) < tol, [config, ': Unexpected discharging behaviour (SoC)'])
end
