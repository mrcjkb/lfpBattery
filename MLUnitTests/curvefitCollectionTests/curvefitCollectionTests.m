function curvefitCollectionTests(fig)
%CURVEFITCOLLECTIONTESTS MLUnit tests for curvefit collections
import lfpBattery.*
if nargin < 1
    fig = false;
end
load(fullfile(pwd, 'curvefitCollectionTests', 'rawCurves.mat'))

%% test functionality of error handling in add() and remove() methods
d = dischargeCurves;
err_msg = 'At least 3 objects must be added to the collection.';
try
    chk = 'error handling failure';
    d.interp(0.9, 1500);
catch ME
    chk = ME.message;
end
assert(isequal(chk, err_msg), chk)
for i = 1:3
    d.dischargeFit(raw(i).V, raw(i).Cd, raw(i).I, const.T_room);
end
d.interp(1, 1500) % error handling should work now
d.remove(raw(i).I);
try
    chk = 'error handling failure';
    d.interp(0.9, 1500);
catch ME
    chk = ME.message;
end
assert(isequal(chk, err_msg), chk) % Error function should be called

for i = 3:6
    d.dischargeFit(raw(i).V, raw(i).Cd, raw(i).I, const.T_room);
end
if fig
    % NOTE: Due to the DoD scale being different for each curve, the curves
    % may be shifted horizontally compared to the originals
    d.plotResults
end

%% MTODO validate spline interpolation of dischargeCurves
I_test = 10;



end

