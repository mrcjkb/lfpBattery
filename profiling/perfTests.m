function perfTests
%PERFTESTS: Function for calling profiling subfunctions

[p, ~] = fileparts(which('perfTests'));
warning('off', 'all')
load(fullfile(p, 'profileBat00.mat'))
warning('on', 'all')
bat.addcurves(d)
bat.powerRequest(100, 60); % To inititialize
profile off
profile on
% tic
profilePR(bat);
% toc
profile off
profile report

end
