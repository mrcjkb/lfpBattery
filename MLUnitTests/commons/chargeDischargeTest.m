function chargeDischargeTest(b, config, nCharge)
% config = topology name as string
tol = 1e-6;
for i = 1:nCharge
    P = b.powerRequest(100, 60);
end
assert(isequal(P, 0), [config, ': Unexpected charging behaviour (Power)'])
assert(0.95 - b.SoC < tol, [config, ': Unexpected charging behaviour (SoC)'])
for i = 1:nCharge
    P = b.powerRequest(-100, 60);
end
assert(isequal(P, 0), [config, ': Unexpected discharging behaviour (Power)'])
assert(abs(b.SoC - 0.2) < tol, [config, ': Unexpected discharging behaviour (SoC)'])
end
