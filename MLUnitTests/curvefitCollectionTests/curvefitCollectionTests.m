function curvefitCollectionTests
%CURVEFITCOLLECTIONTESTS MLUnit tests for curvefit collections
import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests',  'curvefitCollectionTests', 'rawCurves.mat'))
for i = 1:6
    raw(i).Cd = raw(i).Cd .* 1e-3; %#ok<AGROW> % convert from mAh to Ah
end
%% test functionality of error handling in add() and remove() methods
% Error handling removed for performance reasons
d = dischargeCurves;
% err_msg = 'At least 3 objects must be added to the collection.';
% try
%     chk = 'error handling failure';
%     d.interp(0.9, 1500);
% catch ME
%     chk = ME.message;
% end
% assert(isequal(chk, err_msg), chk)
for i = 1:3
    d.dischargeFit(raw(i).V, raw(i).Cd, raw(i).I, const.T_room);
end
d.interp(1, 1500); % error handling should work now
d.remove(raw(i).I);
% try
%     chk = 'error handling failure';
%     d.interp(0.9, 1500);
% catch ME
%     chk = ME.message;
% end
% assert(isequal(chk, err_msg), chk) % Error function should be called

for i = 3:6
    d.dischargeFit(raw(i).V, raw(i).Cd, raw(i).I, const.T_room);
end

% NOTE: Due to the DoD scale being different for each curve, the curves
% may be shifted horizontally compared to the originals
d.plotResults
close gcf

%% MTODO validate spline interpolation of dischargeCurves
idx = 4;
I_test = raw(idx).I;
d.remove(I_test)
Cd = linspace(min(raw(idx).Cd), max(raw(idx).Cd), 1000)';
V = zeros(size(Cd));
for i = 1:numel(Cd)
    V(i) = d.interp(I_test, Cd(i));
end

df = dischargeFit(raw(idx).V, raw(idx).Cd, I_test, const.T_room);
LW = {'LineWidth', 2};
d.plotResults('noRawData', true);
hold on
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
d.add(df);

close gcf

% with x scaled as SoC
LW = {'LineWidth', 2};
d.plotResults('noRawData', true, 'SoCx', true);
hold on
l = findobj(gcf, 'type', 'line');
for i = 1:numel(l)
    l(i).Color = const.grey;
    l(i).LineWidth = 1;
    l(i).LineStyle = '--';
end
pl_df = plot(Cd./max(Cd), df(Cd), 'Color', const.blue, LW{:});
pl_int = plot(Cd./max(Cd), V, 'Color', const.red, LW{:});
legend([pl_df, pl_int, l(1)], ...
    {['fit at ', num2str(I_test),' A'],...
    ['interpolation at ', num2str(I_test), ' A'],...
    'curves used for interpolation'}, ...
    'Location', 'SouthWest')
d.add(df);

close gcf

%% plot low current curve
I_test = 0.01;
Cd = linspace(min(raw(1).Cd), max(raw(1).Cd), 1000)';
V = zeros(size(Cd));
for i = 1:numel(Cd)
    V(i) = d.interp(I_test, Cd(i));
end
d.plotResults('noRawData', true)
l = findobj(gcf, 'type', 'line');
pl_int = plot(Cd, V, 'Color', const.red, LW{:});
legend([pl_int, l(1)], ...
    {'fits',...
    ['interpolation at ', num2str(I_test), ' A']}, ...
    'Location', 'SouthWest')

close gcf
%%
disp('curvefitCollection tests passed')