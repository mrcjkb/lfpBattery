function lfpBatteryTests(test)
%LFPBATTERYTESTS calls MLUnit tests.
%
%LFPBATTERYTESTS('testName') calls one of the following tests:
%'cycleCounter'
%'ageModel'
%'dischargeFit'
%'curvefitCollections'
%'batteryCell'
%'circuitElement'
%'simpleCircuit'

%% Parse inputs
thandles = {@cycleCounterTests, @ageModelTests, @dischargeFitTests, @curvefitCollectionTests, ...
    @batteryCellTests, @circuitElementTests, @simpleCircuitTests, @cccvTests};
TTF = true(numel(thandles), 1);
if nargin > 0
    TTF = ~TTF;
    switch test
        case 'cycleCounter'
            TTF(1) = true;
        case 'ageModel'
            TTF(2) = true;
        case 'dischargeFit'
            TTF(3) = true;
        case 'curvefitCollections'
            TTF(4) = true;
        case 'batteryCell'
            TTF(5) = true;
        case 'circuitElement'
            TTF(6) = true;
        case 'simpleCircuit'
            TTF(7) = true;
        case 'cccv'
            TTF(8) = true;
        otherwise
            error([test, 'is not a valid input argument.'])
    end
end
import lfpBattery.*
st = pwd;
[p, ~] = fileparts(fileparts(which('lfpBatteryTests')));
cd(p)

%% call lfpBattery MLUnit tests
disp(' ')
if nargin < 1
    disp('Beginning MLUnit tests...')
end
for i = 1:numel(thandles)
    if TTF(i)
        feval(thandles{i})
    end
end
if nargin < 1
    disp('All MLUnit tests passed!')
end
disp(' ')
cd(st)
end