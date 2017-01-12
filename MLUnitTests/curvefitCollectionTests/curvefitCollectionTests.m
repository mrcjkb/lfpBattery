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
idx = 4;
I_test = raw(idx).I;
d.remove(I_test)
Cd = linspace(min(raw(idx).Cd), max(raw(idx).Cd), 1000)';
V = zeros(size(Cd));
for i = 1:numel(Cd)
    V(i) = d.interp(I_test, Cd(i));
end
hold on
if fig
    df = dischargeFit(raw(idx).V, raw(idx).Cd, I_test, const.T_room);
    LW = {'LineWidth', 2};
    d.plotResults('noRawData', true);
    l = findobj(gcf, 'type', 'line');
    for i = 1:numel(l)
        l(i).Color = const.grey;
        l(i).LineWidth = 1;
        l(i).LineStyle = '--';
    end
    pl_df = plot(Cd, df(Cd), 'Color', const.blue, LW{:});
    pl_int = plot(Cd, V, 'Color', const.red, LW{:});
    legend([pl_df, pl_int, l(1)], ...
        {['fit at ', num2str(I_test),' A'],...
        ['interpolation at ', num2str(I_test), ' A'],...
        'curves used for interpolation'}, ...
        'Location', 'SouthWest')
end

disp('curvefitCollection tests passed')