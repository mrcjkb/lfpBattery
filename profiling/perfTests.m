function perfTests
%PERFTESTS: Function for calling profiling subfunctions
import lfpBattery.*
[p, ~] = fileparts(fileparts(which('perfTests')));
warning('off', 'all')
load(fullfile(p, 'profiling', 'profileBat00.mat'), 'bat')
load(fullfile(p, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'), 'd')
warning('on', 'all')
bat.addcurves(d)
bat.powerRequest(100, 60); % To inititialize
profile off
% profile on –detail builtin
profile('on', '-detail', 'builtin')
% tic
profilePR(bat);
% toc
profile off
profile report

end
