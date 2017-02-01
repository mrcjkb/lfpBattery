function perfTests
%PERFTESTS: Function for calling profiling subfunctions

[p, ~] = fileparts(which('perfTests'));
warning('off', 'all')
load(fullfile(p, 'profileBat00.mat'))
warning('on', 'all')
profile off
profile on
profilePR(bat);
profile off
profile report
% assert(isequal(bat.V, V), 'Behaviour changed.')

end

