function [ output_args ] = simpleCircuitTests( input_args )
%SIMPLECIRCUITTESTS For testing the simple circuit implementation (assuming
%perfect congruence between cells)

import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))

%%
b = initBatteries(d);
b = b(1);
ps = simplePE(simpleSE(b, 3), 3); % parallel strings of cells

assert(isequal(ps.Vn, 3.*b.Vn), 'unexpected nominal voltage')
assert(isequal(ps.Cn, 3.*b.Cn), 'unexpected nominal capacity')
chargeDischargeTest(ps, 'PS', 1000)


%%

disp('simple circuit tests passed.')

